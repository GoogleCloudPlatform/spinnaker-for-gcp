#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/service_utils.sh

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$PARENT_DIR/spinnaker-for-gcp/scripts/install/properties"

source "$PROPERTIES_FILE"

GCLOUD_PROJECT_ID=$(gcloud info --format='value(config.project)')
GCLOUD_PROJECT_ID=${GCLOUD_PROJECT_ID:-'not set'}

if [ "$GCLOUD_PROJECT_ID" != $PROJECT_ID ]; then
  gcloud config set project $PROJECT_ID

  bold "Your Spinnaker config references GCP project id $PROJECT_ID, but your gcloud default project id was $GCLOUD_PROJECT_ID."
  bold "For safety when executing gcloud commands, 'gcloud config set project $PROJECT_ID' has been used to change the gcloud default."
fi
