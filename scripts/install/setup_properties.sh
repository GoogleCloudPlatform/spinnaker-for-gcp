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

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_duplicate_dirs.sh || exit 1

if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID=$(gcloud info --format='value(config.project)')
fi

if [ -z "$PROJECT_ID" ]; then
  echo "PROJECT_ID must be specified."
  exit 1
fi

PROPERTIES_FILE="$HOME/cloudshell_open/spinnaker-for-gcp/scripts/install/properties"
if [ -f "$PROPERTIES_FILE" ]; then
  bold "The properties file already exists at $PROPERTIES_FILE. Please move it out of the way if you want to generate a new properties file."
  exit 1
fi

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
ZONE=${ZONE:-us-east1-c}
REGION=$(echo $ZONE | cut -d - -f 1,2)

source ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/service_utils.sh

query_redis_instance_names() {
  if [ $(has_service_enabled $1 redis.googleapis.com) ]; then
    # TODO: Should really query redis instances across _all_ regions to ensure no deployment naming collision.
    # TODO: Alternatively, could incorporate region in generated deployment name.
    EXISTING_REDIS_NAMES=$(gcloud redis instances list --region $REGION --project $1 \
                             --filter="name:spinnaker-" \
                             --format="value(name)")

    echo "$EXISTING_REDIS_NAMES"
  fi
}

EXISTING_REDIS_NAMES=$(query_redis_instance_names $PROJECT_ID)

# Also avoid name collisions with potential Shared VPC host project.
if [ $(has_service_enabled $PROJECT_ID compute.googleapis.com) ]; then
  SHARED_VPC_HOST_PROJECT=$(gcloud compute shared-vpc get-host-project $PROJECT_ID --format="value(name)")
fi

if [ "$SHARED_VPC_HOST_PROJECT" ]; then
  SHARED_VPC_HOST_PROJECT_REDIS_NAMES=$(query_redis_instance_names $SHARED_VPC_HOST_PROJECT)

  EXISTING_REDIS_NAMES="$EXISTING_REDIS_NAMES"$'\n'"$SHARED_VPC_HOST_PROJECT_REDIS_NAMES"
fi

EXISTING_DEPLOYMENT_COUNT=$(echo "$EXISTING_REDIS_NAMES" | sed '/^$/d' | wc -l)
NEW_DEPLOYMENT_SUFFIX=$(($EXISTING_DEPLOYMENT_COUNT + 1))
NEW_DEPLOYMENT_NAME="spinnaker-$NEW_DEPLOYMENT_SUFFIX"

while [[ "$(echo "$EXISTING_REDIS_NAMES" | grep ^$NEW_DEPLOYMENT_NAME$ | wc -l)" != "0" ]]; do
  NEW_DEPLOYMENT_NAME="spinnaker-$((++NEW_DEPLOYMENT_SUFFIX))"
done

cat > ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties <<EOL
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

export SPINNAKER_VERSION=1.19.3
export HALYARD_VERSION=1.33.0

export ZONE=$ZONE
export REGION=$REGION

# The specified network must exist, and it must not be a legacy network.
# More info on legacy networks can be found here: https://cloud.google.com/vpc/docs/legacy
export NETWORK=$NETWORK
export SUBNET=$SUBNET

EOL

if [ "$SHARED_VPC_HOST_PROJECT" ]; then
  cat >> ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties <<EOL
# If you want to use a shared network/subnet from the Shared VPC host project, you'll need to perform
# these steps prior to running the setup.sh script:
#   1) Specify the name of the shared network in \$NETWORK up above.
#   2) Specify the name of the shared subnet in \$SUBNET up above.
#   3) Specify the Shared VPC host project id ($SHARED_VPC_HOST_PROJECT) in \$NETWORK_PROJECT below.
#   4) Ensure the subnet referenced by \$SUBNET defines 2 named secondary ranges (one for
#      pods, and one for services).
#   5) Specify the names of the 2 secondary ranges in \$CLUSTER_SECONDARY_RANGE_NAME and
#      \$SERVICES_SECONDARY_RANGE_NAME down below.
EOL
fi

cat >> ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties <<EOL
export NETWORK_PROJECT=\$PROJECT_ID
export NETWORK_REFERENCE=projects/\$NETWORK_PROJECT/global/networks/\$NETWORK
export SUBNET_REFERENCE=projects/\$NETWORK_PROJECT/regions/\$REGION/subnetworks/\$SUBNET
EOL

if [ "$SHARED_VPC_HOST_PROJECT" ]; then
  cat >> ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties <<EOL
export CLUSTER_SECONDARY_RANGE_NAME=
export SERVICES_SECONDARY_RANGE_NAME=
EOL
fi

cat >> ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties <<EOL

# If cluster does not exist, it will be created.
export GKE_CLUSTER=${GKE_CLUSTER:-\$DEPLOYMENT_NAME}

# These are only considered if a new GKE cluster is being created.
export GKE_CLUSTER_VERSION=1.15.12
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
export DOMAIN_NAME=\$DEPLOYMENT_NAME.endpoints.\$PROJECT_ID.cloud.goog

# This email address will be granted permissions as an IAP-Secured Web App User.
export IAP_USER=$(gcloud auth list --format="value(account)" --filter="status=ACTIVE")
EOL

if [ "$SHARED_VPC_HOST_PROJECT" ]; then
  bold "If you want to use a shared network/subnet from the Shared VPC host project ($SHARED_VPC_HOST_PROJECT)," \
    "there are additional instructions you must follow in the properties file. You must perform those steps" \
    "prior to running the setup.sh script:"
  bold "  cloudshell edit ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties"
fi
