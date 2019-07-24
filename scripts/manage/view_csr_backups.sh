#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

PROPERTIES_FILE="$HOME/spinnaker-for-gcp/scripts/install/properties"

if [ -z "$PROPERTIES_FILE" ]; then
  bold "Properties file not found. A properties file is required to locate backups."
  exit 1
fi

source "$PROPERTIES_FILE"

bold "Backups available at https://source.cloud.google.com/$PROJECT_ID/$CONFIG_CSR_REPO"