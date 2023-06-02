#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$PARENT_DIR/spinnaker-for-gcp/scripts/install/properties"

if [ -f "$PROPERTIES_FILE" ]; then
    source "$PROPERTIES_FILE"
fi

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

has_service_enabled() {
  gcloud services list --project $1 \
    --filter="config.name:$2" \
    --format="value(config.name)"
}

check_for_command() {
  COMMAND_PRESENT=$(command -v $1)
  echo $COMMAND_PRESENT
}

check_for_required_binaries() {
  REQUIRED_BINARIES=(git gcloud jq kubectl)

  MISSING_BINARIES=""
  for b in "${REQUIRED_BINARIES[@]}"; do
    BINARY_PATH=$(check_for_command $b)
    if [ -z "$BINARY_PATH" ]; then
      if [ -z $MISSING_BINARIES ]; then
        MISSING_BINARIES="$b"
      else 
        MISSING_BINARIES="$MISSING_BINARIES, $b"
      fi
    fi
  done

  if [ -n "$MISSING_BINARIES" ]; then 
    bold "The following command(s) are required for setup but were not found: $MISSING_BINARIES"
    exit 1
  fi
}

check_for_shared_vpc() {
  if [ "$PROJECT_ID" != "$NETWORK_PROJECT" -a "$1" = true ]; then
    bold "Automated setup of Spinnaker for GCP with a Shared VPC host project is currently unsupported. To proceed, continue the setup in Cloud Shell."
    exit 1
  fi
}

# Get the name of the kubectl context from a cluster name.
#
# $1: Cluster name.
get_kubernetes_context_name() {
  # sed statement removes the current selection column.
  kubectl config get-contexts --no-headers | \
    sed 's/^[^ ]* *//' | \
    awk '$2 ~ /'"${1}"'/ { print $1 }'
}

# Use kubectl config use-context to select the context that points at the
# Spinnaker cluster referenced by install/properties.
select_spinnaker_kubernetes_context() {
  if [[ "${PROJECT_ID}" != "" &&
        "${ZONE}" != "" &&
        "${DEPLOYMENT_NAME}" != "" ]]; then
    local spinnaker_cluster="gke_${PROJECT_ID}_${ZONE}_${DEPLOYMENT_NAME}"
    local spinnaker_context=$(get_kubernetes_context_name "$spinnaker_cluster")
    # If the expected Spinnaker context is missing, try fetching it.
    if [[ "$spinnaker_context" == "" ]]; then
      gcloud container clusters get-credentials \
          --zone "$ZONE" "${DEPLOYMENT_NAME}" || return $?
      spinnaker_context=$(get_kubernetes_context_name "${spinnaker_cluster}")
      if [[ "$spinnaker_context" == "" ]]; then
        bold "Failed to get GKE cluster credentials for ${spinnaker_cluster}"
        return 1
      fi
    fi
    kubectl config use-context "${spinnaker_context}" >/dev/null
  else
    # If install/properties wasn't loaded assume the current context is the
    # Spinnaker cluster.
    local current_context=$(kubectl config current-context)
    if [[ "${current_context}" == "" ]]; then
      bold "No current Kubernetes context is configured."
      return 1
    fi
    bold "WARNING: scripts/install/properties not found, using Kubernetes" \
         "context ${current_context}"
  fi
}

# Generate random alpha-numeric characters in the set [0-9a-z].
#
# $1: Number of characters to generate.
random_identifier() {
  local size=$((${1}))
  if [[ $((size)) -le 0 ]]; then
    echo "Invalid identifier size (${size})." >&2
    return 1
  fi
  cat /dev/urandom 2>/dev/null | \
    tr -dc 'a-z0-9' 2>/dev/null | \
    head -c $((size))
}
