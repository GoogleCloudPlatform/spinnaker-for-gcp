#!/usr/bin/env bash

[ -z "$REPO_PATH" ] && REPO_PATH="$HOME"

source $REPO_PATH/spinnaker-for-gcp/scripts/manage/service_utils.sh

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$REPO_PATH/spinnaker-for-gcp/scripts/install/properties"

if [ ! -f "$PROPERTIES_FILE" ]; then
  bold "No properties file was found. Resetting the management environment."
  git checkout -- $REPO_PATH/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
  exit 0
fi

source "$PROPERTIES_FILE"

# Query for static ip address as a signal that the Spinnaker installation is exposed via a secured endpoint.
export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

if [ -z "$IP_ADDR" ]; then
  bold "Updating Cloud Shell landing page for unsecured Spinnaker..."
  cat $REPO_PATH/spinnaker-for-gcp/scripts/manage/landing_page_base.md $REPO_PATH/spinnaker-for-gcp/scripts/manage/landing_page_unsecured.md \
    | envsubst > $REPO_PATH/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
else
  bold "Updating Cloud Shell landing page for secured Spinnaker..."
  cat $REPO_PATH/spinnaker-for-gcp/scripts/manage/landing_page_base.md $REPO_PATH/spinnaker-for-gcp/scripts/manage/landing_page_secured.md \
    | envsubst > $REPO_PATH/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
fi
