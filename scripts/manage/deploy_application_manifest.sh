#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

if [ ! -f "$HOME/spinnaker-for-gcp/scripts/install/properties" ]; then
  bold "No properties file was found. Not updating GKE Application details view."
  git checkout -- ~/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
  exit 0
fi

source ~/spinnaker-for-gcp/scripts/install/properties

# Query for static ip address as a signal that the Spinnaker installation is exposed via a secured endpoint.
export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

if [ -z "$IP_ADDR" ]; then
  APP_MANIFEST_MIDDLE=spinnaker_application_manifest_middle_unsecured.yaml
else
  APP_MANIFEST_MIDDLE=spinnaker_application_manifest_middle_secured.yaml
fi

kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
cat ~/spinnaker-for-gcp/templates/spinnaker_application_manifest_top.yaml \
  ~/spinnaker-for-gcp/templates/$APP_MANIFEST_MIDDLE \
  ~/spinnaker-for-gcp/templates/spinnaker_application_manifest_bottom.yaml \
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
