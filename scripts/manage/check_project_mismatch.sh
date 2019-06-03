#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/spinnaker-for-gcp/scripts/install/properties

GCLOUD_PROJECT_ID=$(gcloud info --format='value(config.project)')
GCLOUD_PROJECT_ID=${GCLOUD_PROJECT_ID:-'not set'}

if [ "$GCLOUD_PROJECT_ID" != $PROJECT_ID ]; then
  gcloud config set project $PROJECT_ID

  bold "Your Spinnaker config references GCP project id $PROJECT_ID, but your gcloud default project id was $GCLOUD_PROJECT_ID."
  bold "For safety when executing gcloud commands, 'gcloud config set project $PROJECT_ID' has been used to change the gcloud default."
fi
