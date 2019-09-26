#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

check_for_existing_cluster() {
  bold "Checking for existing cluster $GKE_CLUSTER..." >&2

  CLUSTER_EXISTS=$(gcloud beta container clusters list --project $PROJECT_ID \
    --filter="name=$GKE_CLUSTER" \
    --format="value(name)")

  echo $CLUSTER_EXISTS
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
