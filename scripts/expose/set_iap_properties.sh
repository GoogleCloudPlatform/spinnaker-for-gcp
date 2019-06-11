#!/usr/bin/env bash

if [ -z $CLIENT_ID ]; then
  SECRET_JSON=$(kubectl get secret -n spinnaker $SECRET_NAME -o json)

  export CLIENT_ID=$(echo $SECRET_JSON | jq -r .data.client_id | base64 -d)
  export CLIENT_SECRET=$(echo $SECRET_JSON | jq -r .data.client_secret | base64 -d)
fi

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

bold "Querying for backend service id..."

export BACKEND_SERVICE_ID=$(gcloud compute backend-services list --project $PROJECT_ID \
  --filter="iap.oauth2ClientId:$CLIENT_ID AND description:spinnaker/spin-deck" --format="value(id)")

while [ -z "$BACKEND_SERVICE_ID" ]; do
  bold "Waiting for backend service to be provisioned..."
  sleep 30

  export BACKEND_SERVICE_ID=$(gcloud compute backend-services list --project $PROJECT_ID \
    --filter="iap.oauth2ClientId:$CLIENT_ID AND description:spinnaker/spin-deck" --format="value(id)")
done

export AUD_CLAIM=/projects/$PROJECT_NUMBER/global/backendServices/$BACKEND_SERVICE_ID
