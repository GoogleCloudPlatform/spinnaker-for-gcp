#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

err() {
  echo "$*" >&2;
}

source ~/spinnaker-for-gcp/scripts/install/properties

~/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

REQUIRED_APIS="cloudbuild.googleapis.com cloudfunctions.googleapis.com container.googleapis.com endpoints.googleapis.com iap.googleapis.com monitoring.googleapis.com redis.googleapis.com"
NUM_REQUIRED_APIS=$(wc -w <<< "$REQUIRED_APIS")
NUM_ENABLED_APIS=$(gcloud services list --project $PROJECT_ID \
  --filter="config.name:($REQUIRED_APIS)" \
  --format="value(config.name)" | wc -l)

if [ $NUM_ENABLED_APIS != $NUM_REQUIRED_APIS ]; then
  bold "Enabling required APIs ($REQUIRED_APIS)..."
  bold "This phase will take a few minutes (progress will not be reported during this operation)."
  bold
  bold "Once the required APIs are enabled, the remaining components will be installed and configured. The entire installation may take 10 minutes or more."

  gcloud services --project $PROJECT_ID enable $REQUIRED_APIS
fi

SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
  --filter="displayName:$SERVICE_ACCOUNT_NAME" \
  --format='value(email)')

if [ -z "$SA_EMAIL" ]; then
  bold "Creating service account $SERVICE_ACCOUNT_NAME..."

  gcloud iam service-accounts --project $PROJECT_ID create \
    $SERVICE_ACCOUNT_NAME \
    --display-name $SERVICE_ACCOUNT_NAME

  while [ -z "$SA_EMAIL" ]; do
    SA_EMAIL=$(gcloud iam service-accounts --project $PROJECT_ID list \
      --filter="displayName:$SERVICE_ACCOUNT_NAME" \
      --format='value(email)')
    sleep 5
  done
else
  bold "Using existing service account $SERVICE_ACCOUNT_NAME..."
fi

bold "Assigning required roles to $SERVICE_ACCOUNT_NAME..."

K8S_REQUIRED_ROLES=(cloudbuild.builds.editor container.admin logging.logWriter monitoring.admin pubsub.admin storage.admin)
EXISTING_ROLES=$(gcloud projects get-iam-policy --filter bindings.members:$SA_EMAIL $PROJECT_ID \
  --flatten bindings[].members --format="value(bindings.role)")

for r in "${K8S_REQUIRED_ROLES[@]}"; do
  if [ -z "$(echo $EXISTING_ROLES | grep $r)" ]; then
    bold "Assigning role $r..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member serviceAccount:$SA_EMAIL \
      --role roles/$r \
      --format=none
  fi
done

export REDIS_INSTANCE_HOST=$(gcloud redis instances list \
  --project $PROJECT_ID --region $REGION \
  --filter="name=projects/$PROJECT_ID/locations/$REGION/instances/$REDIS_INSTANCE" \
  --format="value(host)")

if [ -z "$REDIS_INSTANCE_HOST" ]; then
  bold "Creating redis instance $REDIS_INSTANCE..."

  gcloud redis instances create $REDIS_INSTANCE --project $PROJECT_ID \
    --region=$REGION --zone=$ZONE --redis-config=notify-keyspace-events=gxE

  export REDIS_INSTANCE_HOST=$(gcloud redis instances list \
    --project $PROJECT_ID --region $REGION \
    --filter="name=projects/$PROJECT_ID/locations/$REGION/instances/$REDIS_INSTANCE" \
    --format="value(host)")
else
  bold "Using existing redis instance $REDIS_INSTANCE ($REDIS_INSTANCE_HOST)..."
fi

# TODO: Could verify ACLs here. In the meantime, error messages should suffice.
gsutil ls $BUCKET_URI

if [ $? != 0 ]; then
  bold "Creating bucket $BUCKET_URI..."

  gsutil mb -p $PROJECT_ID $BUCKET_URI
  gsutil versioning set on $BUCKET_URI
else
  bold "Using existing bucket $BUCKET_URI..."
fi

CLUSTER_EXISTS=$(gcloud beta container clusters list --project $PROJECT_ID \
  --filter="name=$GKE_CLUSTER" \
  --format="value(name)")

if [ -z "$CLUSTER_EXISTS" ]; then
  bold "Creating GKE cluster $GKE_CLUSTER..."

  # TODO: Move some of these config settings to properties file.
  # TODO: Should this be regional instead?
  gcloud beta container clusters create $GKE_CLUSTER --project $PROJECT_ID \
    --zone $ZONE --username "admin" --cluster-version "1.11.8" \
    --machine-type "n1-highmem-4" --image-type "COS" --disk-type "pd-standard" \
    --disk-size "100" --service-account $SA_EMAIL --num-nodes "3" \
    --enable-stackdriver-kubernetes --enable-autoupgrade --enable-autorepair \
    --enable-ip-alias --addons HorizontalPodAutoscaling,HttpLoadBalancing
else
  bold "Using existing GKE cluster $GKE_CLUSTER..."
fi

bold "Retrieving credentials for GKE cluster $GKE_CLUSTER..."

gcloud container clusters get-credentials $GKE_CLUSTER --zone $ZONE --project $PROJECT_ID

GCR_PUBSUB_TOPIC_NAME=projects/$PROJECT_ID/topics/gcr
EXISTING_GCR_PUBSUB_TOPIC_NAME=$(gcloud pubsub topics list --project $PROJECT_ID \
  --filter="name=$GCR_PUBSUB_TOPIC_NAME" --format="value(name)")

if [ -z "$EXISTING_GCR_PUBSUB_TOPIC_NAME" ]; then
  bold "Creating pubsub topic $GCR_PUBSUB_TOPIC_NAME for GCR..."
  gcloud pubsub topics create --project $PROJECT_ID $GCR_PUBSUB_TOPIC_NAME
else
  bold "Using existing pubsub topic $EXISTING_GCR_PUBSUB_TOPIC_NAME for GCR..."
fi

EXISTING_GCR_PUBSUB_SUBSCRIPTION_NAME=$(gcloud pubsub subscriptions list \
  --project $PROJECT_ID \
  --filter="name=projects/$PROJECT_ID/subscriptions/$GCR_PUBSUB_SUBSCRIPTION" \
  --format="value(name)")

if [ -z "$EXISTING_GCR_PUBSUB_SUBSCRIPTION_NAME" ]; then
  bold "Creating pubsub subscription $GCR_PUBSUB_SUBSCRIPTION for GCR..."
  gcloud pubsub subscriptions create --project $PROJECT_ID $GCR_PUBSUB_SUBSCRIPTION \
    --topic=gcr
else
  bold "Using existing pubsub subscription $GCR_PUBSUB_SUBSCRIPTION for GCR..."
fi

GCB_PUBSUB_TOPIC_NAME=projects/$PROJECT_ID/topics/cloud-builds
EXISTING_GCB_PUBSUB_TOPIC_NAME=$(gcloud pubsub topics list --project $PROJECT_ID \
  --filter="name=$GCB_PUBSUB_TOPIC_NAME" --format="value(name)")

if [ -z "$EXISTING_GCB_PUBSUB_TOPIC_NAME" ]; then
  bold "Creating pubsub topic $GCB_PUBSUB_TOPIC_NAME for GCB..."
  gcloud pubsub topics create --project $PROJECT_ID $GCB_PUBSUB_TOPIC_NAME
else
  bold "Using existing pubsub topic $EXISTING_GCB_PUBSUB_TOPIC_NAME for GCB..."
fi

EXISTING_GCB_PUBSUB_SUBSCRIPTION_NAME=$(gcloud pubsub subscriptions list \
  --project $PROJECT_ID \
  --filter="name=projects/$PROJECT_ID/subscriptions/$GCB_PUBSUB_SUBSCRIPTION" \
  --format="value(name)")

if [ -z "$EXISTING_GCB_PUBSUB_SUBSCRIPTION_NAME" ]; then
  bold "Creating pubsub subscription $GCB_PUBSUB_SUBSCRIPTION for GCB..."
  gcloud pubsub subscriptions create --project $PROJECT_ID $GCB_PUBSUB_SUBSCRIPTION \
    --topic=projects/$PROJECT_ID/topics/cloud-builds
else
  bold "Using existing pubsub subscription $GCB_PUBSUB_SUBSCRIPTION for GCB..."
fi

EXISTING_HAL_DEPLOY_APPLY_JOB_NAME=$(kubectl get job -n halyard \
  --field-selector metadata.name=="hal-deploy-apply" \
  -o json | jq -r .items[0].metadata.name)

if [ $EXISTING_HAL_DEPLOY_APPLY_JOB_NAME != 'null' ]; then
  bold "Deleting earlier job $EXISTING_HAL_DEPLOY_APPLY_JOB_NAME..."

  kubectl delete job hal-deploy-apply -n halyard
fi

bold "Provisioning Spinnaker resources..."

envsubst < ~/spinnaker-for-gcp/scripts/install/quick-install.yml | kubectl apply -f -

job_ready() {
  printf "Waiting on job $1 to complete"
  while [[ "$(kubectl get job $1 -n halyard -o \
            jsonpath="{.status.succeeded}")" != "1" ]]; do
    printf "."
    sleep 5
  done
  echo ""
}

job_ready hal-deploy-apply

~/spinnaker-for-gcp/scripts/manage/update_landing_page.sh
~/spinnaker-for-gcp/scripts/manage/deploy_application_manifest.sh

# Delete any existing deployment config secret.
# It will be recreated with up-to-date contents during push_config.sh.
EXISTING_DEPLOYMENT_SECRET_NAME=$(kubectl get secret -n halyard \
  --field-selector metadata.name=="spinnaker-deployment" \
  -o json | jq .items[0].metadata.name)

if [ $EXISTING_DEPLOYMENT_SECRET_NAME != 'null' ]; then
  bold "Deleting Kubernetes secret spinnaker-deployment..."
  kubectl delete secret spinnaker-deployment -n halyard
fi

EXISTING_CLOUD_FUNCTION=$(gcloud functions list --project $PROJECT_ID \
  --format="value(name)" --filter="entryPoint=$CLOUD_FUNCTION_NAME")

if [ -z "$EXISTING_CLOUD_FUNCTION" ]; then
  bold "Deploying audit log cloud function $CLOUD_FUNCTION_NAME..."

  cat ~/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/config_json.template | envsubst > ~/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/config.json
  cat ~/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/index_js.template | envsubst > ~/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/index.js
  gcloud functions deploy $CLOUD_FUNCTION_NAME --source ~/spinnaker-for-gcp/scripts/install/spinnakerAuditLog \
    --trigger-http --memory 2048MB --runtime nodejs8 --project $PROJECT_ID
else
  bold "Using existing audit log cloud function $CLOUD_FUNCTION_NAME..."
fi

# We want the local hal config to match what was deployed.
~/spinnaker-for-gcp/scripts/manage/pull_config.sh
# We want a full backup stored in the bucket and the full deployment config stored in a secret.
~/spinnaker-for-gcp/scripts/manage/push_config.sh

deploy_ready() {
  printf "Waiting on $2 to come online"
  while [[ "$(kubectl get deploy $1 -n spinnaker -o \
            jsonpath="{.status.readyReplicas}")" != \
           "$(kubectl get deploy $1 -n spinnaker -o \
            jsonpath="{.status.replicas}")" ]]; do
    printf "."
    sleep 5
  done
  echo ""
}

deploy_ready spin-gate "API server"
deploy_ready spin-front50 "storage server"
deploy_ready spin-orca "orchestration engine"
deploy_ready spin-kayenta "canary analysis engine"
deploy_ready spin-deck "UI server"

~/spinnaker-for-gcp/scripts/cli/install_hal.sh --version $HALYARD_VERSION
~/spinnaker-for-gcp/scripts/cli/install_spin.sh

# We want a backup containing the newly-created ~/.spin/* files as well.
~/spinnaker-for-gcp/scripts/manage/push_config.sh

echo
bold "Installation complete."
echo
