#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID=$(gcloud info --format='value(config.project)')
fi

if [ -z "$PROJECT_ID" ]; then
  echo "PROJECT_ID must be specified."
  exit 1
fi

check_for_spinnaker_deployment() {
  bold "Checking for Spinnaker deployment in Kubernetes context $1..."

  SPINNAKER_APPLICATION_LIST_JSON=$(kubectl get applications -n spinnaker -l app.kubernetes.io/name=spinnaker --output json --context $1)
  SPINNAKER_APPLICATION_COUNT=$(echo $SPINNAKER_APPLICATION_LIST_JSON | jq '.items | length')

  if [ "$SPINNAKER_APPLICATION_COUNT" == "0" ] || [ -z $SPINNAKER_APPLICATION_COUNT ]; then
    bold "No Spinnaker deployment was found via context $1."
  elif [ "$SPINNAKER_APPLICATION_COUNT" == "1" ]; then
    bold "Found Spinnaker deployment $(echo $SPINNAKER_APPLICATION_LIST_JSON | jq -r .items[0].metadata.name) via context $1."

    if [ $2 ]; then
      bold "You can select this context using: kubectl config use-context $1"
    fi

    if [ $3 ]; then
      kubectl config use-context $1
    fi
  else
    bold "Multiple Spinnaker deployments were found in cluster $1. This should never be the case."
    exit 1
  fi
}

bold "Querying for current Kubernetes context..."

CURRENT_CONTEXT=$(kubectl config current-context)

if [ "$?" != "0" ]; then
  CONTEXT_LIST=$(kubectl config get-contexts -o name)
  CONTEXT_COUNT=$(echo "$CONTEXT_LIST" | sed '/^$/d' | wc -l)

  if [ "$CONTEXT_COUNT" == "0" ]; then
    bold "No contexts configured."
    bold "Querying for GKE clusters in project $PROJECT_ID..."

    CLUSTER_LIST=$(gcloud beta container clusters list --format json --project $PROJECT_ID)
    CLUSTER_COUNT=$(echo $CLUSTER_LIST | jq '. | length')

    if [ "$CLUSTER_COUNT" == "0" ]; then
      bold "No GKE clusters were found in project $PROJECT_ID."
      exit 1
    fi

    for (( i=0; i<$CLUSTER_COUNT; i++ )); do
      # TODO: Determine implications of encountering non-zonal cluster here.
      bold "Retrieving credentials from project $PROJECT_ID for cluster" \
        "$(echo $CLUSTER_LIST | jq -r ".[$i].name")" \
        "in zone $(echo $CLUSTER_LIST | jq -r ".[$i].zone")..."

      gcloud container clusters get-credentials $(echo $CLUSTER_LIST | jq -r ".[$i].name") \
        --zone $(echo $CLUSTER_LIST | jq -r ".[$i].zone") --project $PROJECT_ID
    done

    # Removing current context since gcloud container clusters get-credentials implicitly sets it.
    # We want to avoid this behavior since their may be multiple clusters in this project.
    # If there is exactly one cluster, the context will be automatically selected in the next steps anyway.
    sed -i"" -e"s/^current-context:.*$/current-context:/" ~/.kube/config
  fi

  # Now that we have retrieved credentials for each cluster in this project, query the configured contexts again.
  CONTEXT_LIST=$(kubectl config get-contexts -o name)
  CONTEXT_COUNT=$(echo "$CONTEXT_LIST" | sed '/^$/d' | wc -l)

  if [ "$CONTEXT_COUNT" == "1" ]; then
    bold "There is exactly one Kubernetes context configured: $CONTEXT_LIST"

    # Since there is exactly one context configured, we'll set that as the current context.
    check_for_spinnaker_deployment $CONTEXT_LIST "" "select_context"
  else
    bold "There are multiple Kubernetes contexts configured."

    CONTEXT_LIST=($CONTEXT_LIST)

    # Since there are multiple contexts configured, we will just query for Spinnaker deployments and generate
    # commands that can be used to select a current context.
    for c in "${CONTEXT_LIST[@]}"; do
      check_for_spinnaker_deployment $c "generate_command"
    done

  fi
else
  bold "Using context $CURRENT_CONTEXT."

  # There is a current context, so we will just query for a Spinnaker deployment.
  check_for_spinnaker_deployment $CURRENT_CONTEXT
fi
