#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/service_utils.sh

check_for_existing_cluster() {
  bold "Checking for existing cluster $GKE_CLUSTER..." >&2

  CLUSTER_EXISTS=$(gcloud container clusters list --project $PROJECT_ID \
    --filter="name=$GKE_CLUSTER" \
    --format="value(name)")

  echo $CLUSTER_EXISTS
}

check_existing_cluster_location() {
  bold "Verifying location of existing cluster $GKE_CLUSTER..."

  # Query for cluster in specified zone, just in case there are multiple clusters with the same name.
  CLUSTER_EXISTS_IN_SPECIFIED_ZONE=$(gcloud container clusters list --project $PROJECT_ID \
    --zone=$ZONE \
    --filter="name=$GKE_CLUSTER" \
    --format="value(location)")

  # If it's not in the specified zone, figure out where exactly it is.
  if [ -z "$CLUSTER_EXISTS_IN_SPECIFIED_ZONE" ]; then
    EXISTING_CLUSTER_LOCATION=$(gcloud container clusters list --project $PROJECT_ID \
      --filter="name=$GKE_CLUSTER" \
      --format="value(location)")

    LOCATION_IS_REGION=$(gcloud compute regions list --project $PROJECT_ID \
      --filter="name=$EXISTING_CLUSTER_LOCATION" \
      --format="value(name)")

    if [ -n "$LOCATION_IS_REGION" ]; then
      bold "Your pre-existing cluster $GKE_CLUSTER is regional; we do not support regional clusters."
      exit 1
    fi
  fi
}

check_existing_cluster_prereqs() {
  EXISTING_CLUSTER_DESCRIPTION=$(gcloud container clusters describe $GKE_CLUSTER --zone $ZONE --format json)
  IP_ALIASES_ENABLED=$(echo $EXISTING_CLUSTER_DESCRIPTION | jq .ipAllocationPolicy.useIpAliases)

  if [ "$IP_ALIASES_ENABLED" != "true" ]; then
    bold "Your pre-existing cluster must have IP Aliases enabled."
    exit 1
  fi

  NODE_CONFIG_SERVICE_ACCOUNT=$(echo $EXISTING_CLUSTER_DESCRIPTION | jq -r .nodeConfig.serviceAccount)

  # If using the "Compute Engine default service account", Full Cloud Platform scope is required for its nodes.
  if [ "$NODE_CONFIG_SERVICE_ACCOUNT" == "default" ]; then
    NODES_HAVE_CLOUD_PLATFORM_SCOPE=$(echo $EXISTING_CLUSTER_DESCRIPTION | \
      jq '[.nodeConfig.oauthScopes[] == "https://www.googleapis.com/auth/cloud-platform"] | any')

    if [ "$NODES_HAVE_CLOUD_PLATFORM_SCOPE" != "true" ]; then
      bold "Your pre-existing cluster is using the \"Compute Engine default service account\". As such," \
        "your nodes must have Full Cloud Platform scope."
      bold "In general, we recommend using an IAM-backed service account instead. An IAM-backed service" \
        "account will be assigned the required roles during the Spinnaker for GCP setup process."
      exit 1
    fi
  fi
}
