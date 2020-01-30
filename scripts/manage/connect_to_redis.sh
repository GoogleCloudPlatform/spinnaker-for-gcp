#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

bold "Resolving redis host..."

export REDIS_INSTANCE_HOST=$(gcloud redis instances list \
  --project $PROJECT_ID --region $REGION \
  --filter="name=projects/$PROJECT_ID/locations/$REGION/instances/$REDIS_INSTANCE" \
  --format="value(host)")

bold "Locating redis-cli deployment..."

REDIS_CLI_DEPLOYMENT=$(kubectl get deployments -n spinnaker --field-selector metadata.name=redisbox \
  --output name)

if [ -z $REDIS_CLI_DEPLOYMENT ]; then
  bold "Deploying redis-cli..."

  kubectl run redisbox --image=gcr.io/google_containers/redis:v1 -n spinnaker
fi

bold "Waiting for redis-cli deployment to become available..."

kubectl wait --for condition=available deployment redisbox -n spinnaker

bold "Locating redis-cli pod..."

REDIS_CLI_POD=$(kubectl get pods -n spinnaker -l run=redisbox \
  -o=jsonpath='{.items[0].metadata.name}')

bold "Connecting to redis-cli pod and specifying redis host $REDIS_INSTANCE_HOST..."

kubectl exec -it $REDIS_CLI_POD -n spinnaker -- redis-cli -h $REDIS_INSTANCE_HOST

bold "Deleting redis-cli deployment..."

kubectl delete deployment redisbox -n spinnaker
