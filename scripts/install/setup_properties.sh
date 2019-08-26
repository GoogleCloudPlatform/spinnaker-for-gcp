#!/usr/bin/env bash

# PROJECT_ID should be set, but we will try to determine via gcloud config if not set.
# DEPLOYMENT_NAME, GKE_CLUSTER and ZONE are optional.
# If GKE_CLUSTER is set, ZONE is required. (This indicates that we should install in an existing cluster.)
# If using a pre-existing cluster, that cluster must have:
#   - IP aliases enabled (since we are using a hosted Redis instance)
#   - Full Cloud Platform scope for its nodes (if using the default service account)
# ZONE can be set and GKE_CLUSTER left unset. (This indicates we should create a new cluster in $ZONE.)

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

~/spinnaker-for-gcp/scripts/manage/check_duplicate_dirs.sh || exit 1

if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID=$(gcloud info --format='value(config.project)')
fi

if [ -z "$PROJECT_ID" ]; then
  echo "PROJECT_ID must be specified."
  exit 1
fi

PROPERTIES_FILE="$HOME/spinnaker-for-gcp/scripts/install/properties"
if [ -f "$PROPERTIES_FILE" ]; then
  bold "The properties file already exists at $PROPERTIES_FILE. Please move it out of the way if you want to generate a new properties file."
else
  if [ "$GKE_CLUSTER" ]; then
    if [ -z "$ZONE" ]; then
      echo "If GKE_CLUSTER is specified, ZONE must also be specified."
      exit 1
    fi

    # Since cluster already exists, must resolve service account from the cluster.
    EXISTING_SA_EMAIL=$(gcloud beta container clusters describe --project $PROJECT_ID \
                          --zone $ZONE $GKE_CLUSTER --format="value(nodeConfig.serviceAccount)")

    if [ -z $EXISTING_SA_EMAIL ]; then
      echo "Unable to resolve service account from existing cluster $GKE_CLUSTER in zone $ZONE."
      exit 1
    fi

    if [ "$EXISTING_SA_EMAIL" == "default" ]; then
      SERVICE_ACCOUNT_NAME="Compute Engine default service account"
    else
      SERVICE_ACCOUNT_NAME=$(echo $EXISTING_SA_EMAIL | cut -d @ -f 1)
    fi
  fi

  NETWORK="default"
  SUBNET="default"
  ZONE=${ZONE:-us-west1-b}
  REGION=$(echo $ZONE | cut -d - -f 1,2)

  # Check if Redis api is enabled.
  if [ $(gcloud services list --project $PROJECT_ID \
           --filter="config.name:redis.googleapis.com" \
           --format="value(config.name)") ]; then
    # Query existing Redis instances so we can avoid naming collisions.
    # TODO: Should really query redis instances across _all_ regions to ensure no deployment naming collision.
    # TODO: Alternatively, could incorporate region in generated deployment name.
    EXISTING_REDIS_NAMES=$(gcloud redis instances list --region $REGION --project $PROJECT_ID \
                             --filter="name:spinnaker-" \
                             --format="value(name)")
    EXISTING_DEPLOYMENT_COUNT=$(echo "$EXISTING_REDIS_NAMES" | sed '/^$/d' | wc -l)
    NEW_DEPLOYMENT_SUFFIX=$(($EXISTING_DEPLOYMENT_COUNT + 1))
    NEW_DEPLOYMENT_NAME="spinnaker-$NEW_DEPLOYMENT_SUFFIX"

    while [[ "$(echo "$EXISTING_REDIS_NAMES" | grep ^$NEW_DEPLOYMENT_NAME$ | wc -l)" != "0" ]]; do
      NEW_DEPLOYMENT_NAME="spinnaker-$((++NEW_DEPLOYMENT_SUFFIX))"
    done
  else
    NEW_DEPLOYMENT_NAME="spinnaker-1"
  fi

  cat > ~/spinnaker-for-gcp/scripts/install/properties <<EOL
#!/usr/bin/env bash

# This file is generated just once per Spinnaker installation, prior to running setup.sh.
# You can make changes to this file before running setup.sh for the first time.
# If setup.sh is interrupted, you can run it again at any point and it will finish any incomplete steps.
# Do not change this file once you have run setup.sh for the first time.
# If you want to provision a new Spinnaker installation, whether in the same project or a different project,
#   simply wait until setup.sh completes and delete this file (or the entire cloned repo) from your
#   Cloud Shell home directory. Then you can relaunch the provision-spinnaker.md tutorial and generate a new
#   properties file for use in provisioning a new Spinnaker installation.

export PROJECT_ID=$PROJECT_ID
export DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-$NEW_DEPLOYMENT_NAME}

export SPINNAKER_VERSION=1.14.11
export HALYARD_VERSION=1.22.1

# The specified network must exist, and it must not be a legacy network.
# More info on legacy networks can be found here: https://cloud.google.com/vpc/docs/legacy
export NETWORK=$NETWORK
export SUBNET=$SUBNET

# If cluster does not exist, it will be created.
export GKE_CLUSTER=${GKE_CLUSTER:-\$DEPLOYMENT_NAME}
export ZONE=$ZONE
export REGION=$REGION

# These are only considered if a new GKE cluster is being created.
export GKE_CLUSTER_VERSION=1.12.7
export GKE_MACHINE_TYPE=n1-highmem-4
export GKE_DISK_TYPE=pd-standard
export GKE_DISK_SIZE=100
export GKE_NUM_NODES=3

# See TZ column in https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
export TIMEZONE=$(cat /etc/timezone)

# If service account does not exist, it will be created.
export SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-"\$DEPLOYMENT_NAME-acc-$(date +"%s")"}"

# If Cloud Memorystore Redis instance does not exist, it will be created.
export REDIS_INSTANCE=\$DEPLOYMENT_NAME

# If bucket does not exist, it will be created.
export BUCKET_NAME="\$DEPLOYMENT_NAME-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 20 | head -n 1)-$(date +"%s")"
export BUCKET_URI="gs://\$BUCKET_NAME"

# If CSR repo does not exist, it will be created.
export CONFIG_CSR_REPO=\$DEPLOYMENT_NAME-config

# Used to authenticate calls to the audit log Cloud Function.
export AUDIT_LOG_UNAME="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 20 | head -n 1)-$(date +"%s")"
export AUDIT_LOG_PW="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 20 | head -n 1)-$(date +"%s")"

export CLOUD_FUNCTION_NAME="\${DEPLOYMENT_NAME//-}AuditLog"

export GCR_PUBSUB_SUBSCRIPTION=\$DEPLOYMENT_NAME-gcr-pubsub-subscription
export GCB_PUBSUB_SUBSCRIPTION=\$DEPLOYMENT_NAME-gcb-pubsub-subscription

export PUBSUB_NOTIFICATION_PUBLISHER=\$DEPLOYMENT_NAME-publisher
export PUBSUB_NOTIFICATION_TOPIC=\$DEPLOYMENT_NAME-notifications-topic

# The properties following this line are only relevant if you intend to expose your new Spinnaker instance.
export STATIC_IP_NAME=\$DEPLOYMENT_NAME-external-ip
export MANAGED_CERT=\$DEPLOYMENT_NAME-managed-cert
export SECRET_NAME=\$DEPLOYMENT_NAME-oauth-client-secret

# If you own a domain name and want to use that instead of this automatically-assigned one,
# specify it here (you must be able to configure the dns settings).
export DOMAIN_NAME=\$DEPLOYMENT_NAME.endpoints.$PROJECT_ID.cloud.goog

# This email address will be granted permissions as an IAP-Secured Web App User.
export IAP_USER=$(gcloud auth list --format="value(account)" --filter="status=ACTIVE")
EOL
fi
