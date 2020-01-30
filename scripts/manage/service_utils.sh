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