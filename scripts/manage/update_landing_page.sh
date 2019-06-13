#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

if [ ! -f "$HOME/spinnaker-for-gcp/scripts/install/properties" ]; then
  bold "No properties file was found. Resetting the management environment."
  git checkout -- ~/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
  exit 0
fi

source ~/spinnaker-for-gcp/scripts/install/properties

# Query for static ip address as a signal that the Spinnaker installation is exposed via a secured endpoint.
export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

if [ -z "$IP_ADDR" ]; then
  bold "Updating Cloud Shell landing page for unsecured Spinnaker..."
  cat ~/spinnaker-for-gcp/scripts/manage/landing_page_base.md ~/spinnaker-for-gcp/scripts/manage/landing_page_unsecured.md \
    | envsubst > ~/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
else
  bold "Updating Cloud Shell landing page for secured Spinnaker..."
  cat ~/spinnaker-for-gcp/scripts/manage/landing_page_base.md ~/spinnaker-for-gcp/scripts/manage/landing_page_secured.md \
    | envsubst > ~/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
fi
