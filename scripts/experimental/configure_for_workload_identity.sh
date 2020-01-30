#!/usr/bin/env bash

# Prior to running this script, please ensure that you are running these versions or later:
# export SPINNAKER_VERSION=release-1.17.x-latest-validated
# export HALYARD_VERSION=1.26.0
#
# This script is intended to be run after the initial setup.sh script completes and Spinnaker is up
# and running (without Workload Identity enabled).
#
# The expected workflow is as follows:
#   - Generate the properties file by running the setup_properties.sh script
#   - Modify the properties file to specify the above 2 Spinnaker/Halyard versions (or later versions)
#   - Run setup.sh
#   - Once Spinnaker is up and running, run this (configure_for_workload_identity.sh) script
#
# Note that this script results in each Spinnaker pod still using the default Kubernetes service account,
#   and the default service account in the halyard and spinnaker namespaces being bound to one Google
#   service account (spinnaker-wi-acct). If you want to specify a different Kubernetes service account
#   for any service, you can do so via the `serviceAccountName` setting described here:
#   https://www.spinnaker.io/reference/halyard/custom/#kubernetes
#   You would also need to make the appropriate bindings between that Kubernetes service account and a
#   Google service account.
#
#   The roles assigned are sufficient for deployment to GKE. If you intend to deploy to GCE or GAE, you
#     will need to assign the appropriate roles to the spinnaker-wi-acct Google service account, similar
#     to what we do in these helper scripts for the non-Workload Identity setup:
#       https://github.com/GoogleCloudPlatform/spinnaker-for-gcp/blob/master/scripts/manage/add_gce_account.sh
#       https://github.com/GoogleCloudPlatform/spinnaker-for-gcp/blob/master/scripts/manage/add_gae_account.sh

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

PROPERTIES_FILE="$HOME/cloudshell_open/spinnaker-for-gcp/scripts/install/properties"

source "$PROPERTIES_FILE"

bold "Enabling workload identity on cluster $GKE_CLUSTER in project $PROJECT_ID..."
gcloud beta container clusters update $GKE_CLUSTER \
  --zone=$ZONE \
  --identity-namespace=$PROJECT_ID.svc.id.goog \
  --project=$PROJECT_ID

unset CLUSTER_STATUS

while [ "$CLUSTER_STATUS" != "RUNNING" ]; do
  CLUSTER_STATUS=$(gcloud container clusters describe $GKE_CLUSTER \
    --zone=$ZONE \
    --format="value(status)" \
    --project=$PROJECT_ID)
  sleep 5
 echo -n .
done
echo

KSA_NAME=default
GSA_NAME=spinnaker-wi-acct
GSA_DISPLAY_NAME="Spinnaker Workload Identity service account"

bold "Creating Google service account $GSA_NAME..."
gcloud iam service-accounts create $GSA_NAME \
  --display-name="$GSA_DISPLAY_NAME" \
  --project=$PROJECT_ID

GSA_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:$GSA_DISPLAY_NAME" \
  --format="value(email)" \
  --project=$PROJECT_ID)

while [ -z "$GSA_EMAIL" ]; do
  GSA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:$GSA_DISPLAY_NAME" \
    --format="value(email)" \
    --project=$PROJECT_ID)
  sleep 5
  echo -n .
done
echo

bold "Assigning required roles to $GSA_DISPLAY_NAME..."

K8S_REQUIRED_ROLES=(cloudbuild.builds.editor container.admin logging.logWriter monitoring.admin pubsub.admin storage.admin)
EXISTING_ROLES=$(gcloud projects get-iam-policy $PROJECT_ID \
  --filter="bindings.members:$GSA_EMAIL" \
  --format="value(bindings.role)" \
  --flatten="bindings[].members")

for r in "${K8S_REQUIRED_ROLES[@]}"; do
  if [ -z "$(echo $EXISTING_ROLES | grep $r)" ]; then
    bold "Assigning role $r..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$GSA_EMAIL" \
      --role="roles/$r" \
      --format="none"
  fi
done

bold "Creating Cloud IAM policy binding between Kubernetes service account halyard/$KSA_NAME and Google service account $GSA_NAME..."
gcloud iam service-accounts add-iam-policy-binding \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[halyard/$KSA_NAME]" \
  --project=$PROJECT_ID \
  $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

bold "Creating Cloud IAM policy binding between Kubernetes service account spinnaker/$KSA_NAME and Google service account $GSA_NAME..."
gcloud iam service-accounts add-iam-policy-binding \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[spinnaker/$KSA_NAME]" \
  --project=$PROJECT_ID \
  $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

bold "Annotating Kubernetes service account halyard/$KSA_NAME with Google service account to use ($GSA_NAME)..."
kubectl annotate serviceaccount \
  --namespace halyard \
  $KSA_NAME \
  iam.gke.io/gcp-service-account=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

bold "Annotating Kubernetes service account spinnaker/$KSA_NAME with Google service account to use ($GSA_NAME)..."
kubectl annotate serviceaccount \
  --namespace spinnaker \
  $KSA_NAME \
  iam.gke.io/gcp-service-account=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

NODE_POOL_NAME=$(gcloud container clusters describe $GKE_CLUSTER \
  --zone=$ZONE \
  --format="value(nodePools[0].name)" \
  --project=$PROJECT_ID)

bold "Enabling GKE_METADATA_SERVER on node pool $NODE_POOL_NAME..."
gcloud beta container node-pools update $NODE_POOL_NAME \
  --cluster=$GKE_CLUSTER \
  --zone=$ZONE \
  --workload-metadata-from-node=GKE_METADATA_SERVER \
  --project=$PROJECT_ID
