#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

source $PARENT_DIR/scripts/manage/service_utils.sh

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$PARENT_DIR/scripts/install/properties"

source "$PROPERTIES_FILE"
echo $GCLOUD_PROJECT_ID
gcloud info --format='value(config.project)'
GCLOUD_PROJECT_ID=$(gcloud info --format='value(config.project)')
echo GCLOUD_PROJECT_ID
GCLOUD_PROJECT_ID=${GCLOUD_PROJECT_ID:-'not set'}
echo $GCLOUD_PROJECT_ID

if [ "$GCLOUD_PROJECT_ID" != $PROJECT_ID ]; then
  gcloud config set project $PROJECT_ID

  echo "Your Spinnaker config references GCP project id $PROJECT_ID, but your gcloud default project id was $GCLOUD_PROJECT_ID."
  echo "For safety when executing gcloud commands, 'gcloud config set project $PROJECT_ID' has been used to change the gcloud default."
fi
