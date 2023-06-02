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

select_spinnaker_kubernetes_context || exit $?

kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
cat $PARENT_DIR/spinnaker-for-gcp/templates/spinnaker_application_manifest_top.yaml \
  $PARENT_DIR/spinnaker-for-gcp/templates/$APP_MANIFEST_MIDDLE \
  $PARENT_DIR/spinnaker-for-gcp/templates/spinnaker_application_manifest_bottom.yaml \
  | envsubst | kubectl apply -f -

bold "Labeling resources as components of application $DEPLOYMENT_NAME..."
# List of expected Spinnaker components for a default deployment.
declare -r DEFAULT_COMPONENTS="\
spin-clouddriver
spin-deck
spin-echo
spin-front50
spin-gate
spin-igor
spin-kayenta
spin-orca
spin-rosco"

for object_type in services deployments; do
  default_objects=$(echo "${DEFAULT_COMPONENTS}" | sed "s@^@${object_type}/&@")
  for name in $(
     (
       echo "${default_objects}";
       # Fold-in optional components if they've been added to the cluster.
       kubectl get "${object_type}" -n spinnaker -o name | \
         sed 's@^deployment[^/]*/@deployments/@;s@^service[^/]*/@services/@'
     ) | sort -u ); do
    kubectl label --overwrite -n spinnaker "${name}" \
      app.kubernetes.io/name=$DEPLOYMENT_NAME -o name
  done
done