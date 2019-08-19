#!/usr/bin/env bash

# The logic is roughly as follows:
#   Check each configured context that is in the specified project for a Spinnaker deployment.
#   If there are no matching contexts that contain a deployment, retrieve credentials for all
#     of the specified project's clusters and check each of the newly-configured contexts for
#     a Spinnaker deployment.
#   If there is exactly one matching context, and it contains a deployment, set that as the current context.
#   Otherwise, generate a 'kubectl config use-context' command for each matching context that contains a
#     deployment (and indicate if one of them is already set as the current context).

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
  if [ "$1" == "$CURRENT_CONTEXT" ]; then
    CURRENT_CONTEXT_MATCH=" (CURRENT CONTEXT)"
  else
    unset CURRENT_CONTEXT_MATCH
  fi

  PROJECT_CONTAINING_CLUSTER=$(echo $1 | cut -d _ -f 2)

  if [ "$PROJECT_CONTAINING_CLUSTER" == "$PROJECT_ID" ]; then
    bold "Checking for Spinnaker deployment in Kubernetes context $1..."

    SPINNAKER_APPLICATION_LIST_JSON=$(kubectl get applications -n spinnaker -l app.kubernetes.io/name=spinnaker --output json --context $1)
    SPINNAKER_APPLICATION_COUNT=$(echo $SPINNAKER_APPLICATION_LIST_JSON | jq '.items | length')

    if [ "$SPINNAKER_APPLICATION_COUNT" == "0" ] || [ -z $SPINNAKER_APPLICATION_COUNT ]; then
      bold "No Spinnaker deployment was found via context $1$CURRENT_CONTEXT_MATCH."
    elif [ "$SPINNAKER_APPLICATION_COUNT" == "1" ]; then
      bold "Found Spinnaker deployment $(echo $SPINNAKER_APPLICATION_LIST_JSON | jq -r .items[0].metadata.name) via context $1$CURRENT_CONTEXT_MATCH."

      FOUND_MATCH_IN_PROJECT=true

      if [ $2 ] && [ -z "$CURRENT_CONTEXT_MATCH" ]; then
        bold "You can select this context using: kubectl config use-context $1"
      fi

      if [ $3 ]; then
        kubectl config use-context $1
      fi
    else
      bold "Multiple Spinnaker deployments were found in cluster $1. This should never be the case."

      if [ "$CURRENT_CONTEXT_MATCH" ]; then
        clear_current_context
      fi

      exit 1
    fi
  else
    # The context is not from the specified project.

    if [ "$CURRENT_CONTEXT_MATCH" ]; then
      clear_current_context
    fi
  fi
}

clear_current_context() {
  sed -i"" -e"s/^current-context:.*$/current-context:/" ~/.kube/config
}

check_all_contexts() {
  if [ "$CONTEXT_COUNT" == "1" ]; then
    # Since there is exactly one context configured, we'll set that as the current context (if a deployment is found).
    check_for_spinnaker_deployment $CONTEXT_LIST "" "select_context"
  else
    CONTEXT_LIST=($CONTEXT_LIST)

    # Since there are multiple contexts configured, we will just query for Spinnaker deployments and generate
    # commands that can be used to select a current context.
    for c in "${CONTEXT_LIST[@]}"; do
      check_for_spinnaker_deployment $c "generate_command"
    done
  fi
}

query_configured_contexts() {
  CONTEXT_LIST=$(kubectl config get-contexts -o name)
  CONTEXT_COUNT=$(echo "$CONTEXT_LIST" | sed '/^$/d' | wc -l)
}

get_all_project_cluster_credentials() {
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
  # We want to avoid this behavior since there may be multiple clusters in this project.
  # If there is exactly one cluster, the context will be automatically selected in the next steps anyway.
  clear_current_context
}

bold "Querying for current Kubernetes context..."

CURRENT_CONTEXT=$(kubectl config current-context)

query_configured_contexts

if [ "$CONTEXT_COUNT" != "0" ]; then
  check_all_contexts
fi

if [ -z "$FOUND_MATCH_IN_PROJECT" ]; then
  get_all_project_cluster_credentials
  query_configured_contexts
  check_all_contexts
fi
