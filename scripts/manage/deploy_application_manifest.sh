#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/service_utils.sh

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$PARENT_DIR/spinnaker-for-gcp/scripts/install/properties"

if [ ! -f "$PROPERTIES_FILE" ]; then
  bold "No properties file was found. Not updating GKE Application details view."
  git checkout -- $PARENT_DIR/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
  exit 0
fi

source "$PROPERTIES_FILE"

# Query for static ip address as a signal that the Spinnaker installation is exposed via a secured endpoint.
export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

if [ -z "$IP_ADDR" ]; then
  APP_MANIFEST_MIDDLE=spinnaker_application_manifest_middle_unsecured.yaml
else
  APP_MANIFEST_MIDDLE=spinnaker_application_manifest_middle_secured.yaml
fi

kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
cat $PARENT_DIR/spinnaker-for-gcp/templates/spinnaker_application_manifest_top.yaml \
  $PARENT_DIR/spinnaker-for-gcp/templates/$APP_MANIFEST_MIDDLE \
  $PARENT_DIR/spinnaker-for-gcp/templates/spinnaker_application_manifest_bottom.yaml \
  | envsubst | kubectl apply -f -

bold "Labeling resources as components of application $DEPLOYMENT_NAME..."
kubectl label service --overwrite -n spinnaker spin-clouddriver app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-deck app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-echo app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-front50 app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-gate app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-igor app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-kayenta app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-orca app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label service --overwrite -n spinnaker spin-rosco app.kubernetes.io/name=$DEPLOYMENT_NAME -o name

kubectl label deployment --overwrite -n spinnaker spin-clouddriver app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-deck app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-echo app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-front50 app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-gate app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-igor app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-kayenta app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-orca app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
kubectl label deployment --overwrite -n spinnaker spin-rosco app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
