#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

if [ "$CI" == true ]; then
  HAL_PARENT_DIR=$PARENT_DIR
else
  HAL_PARENT_DIR=$HOME
fi

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/service_utils.sh

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$PARENT_DIR/spinnaker-for-gcp/scripts/install/properties"

$PARENT_DIR/spinnaker-for-gcp/scripts/manage/check_duplicate_dirs.sh || exit 1

CURRENT_CONTEXT=$(kubectl config current-context)

if [ "$?" != "0" ]; then
  bold "No current Kubernetes context is configured."
  exit 1
fi

HALYARD_POD=spin-halyard-0

TEMP_DIR=$(mktemp -d -t halyard.XXXXX)
pushd $TEMP_DIR

mkdir .hal

# Remove local config so persistent config from Halyard Daemon pod can be copied into place.
bold "Removing $HAL_PARENT_DIR/.hal..."
rm -rf $HAL_PARENT_DIR/.hal

# Copy persistent config into place.
bold "Copying halyard/$HALYARD_POD:/home/spinnaker/.hal into $HAL_PARENT_DIR/.hal..."

kubectl cp halyard/$HALYARD_POD:/home/spinnaker/.hal .hal

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/restore_config_utils.sh
rewrite_hal_key_paths

# We want just these subdirs from the Halyard Daemon pod to be copied into place in $HAL_PARENT_DIR/.hal.
copy_hal_subdirs
cp .hal/config $HAL_PARENT_DIR/.hal

EXISTING_DEPLOYMENT_SECRET_NAME=$(kubectl get secret -n halyard \
  --field-selector metadata.name=="spinnaker-deployment" \
  -o json | jq .items[0].metadata.name)

if [ $EXISTING_DEPLOYMENT_SECRET_NAME != 'null' ]; then
  bold "Restoring Spinnaker deployment config files from Kubernetes secret spinnaker-deployment..."
  DEPLOYMENT_SECRET_DATA=$(kubectl get secret spinnaker-deployment -n halyard -o json)

  extract_to_file_if_defined() {
    DATA_ITEM_VALUE=$(echo $DEPLOYMENT_SECRET_DATA | jq -r ".data.\"$1\"")

    if [ $DATA_ITEM_VALUE != 'null' ]; then
      echo $DATA_ITEM_VALUE | base64 -d > $2
    fi
  }

  extract_to_file_if_defined properties "$PROPERTIES_FILE"
  extract_to_file_if_defined config.json $PARENT_DIR/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/config.json
  extract_to_file_if_defined index.js $PARENT_DIR/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/index.js
  extract_to_file_if_defined configure_iap_expanded.md $PARENT_DIR/spinnaker-for-gcp/scripts/expose/configure_iap_expanded.md
  extract_to_file_if_defined openapi_expanded.yml $PARENT_DIR/spinnaker-for-gcp/scripts/expose/openapi_expanded.yml
  mkdir -p ~/.spin
  extract_to_file_if_defined config ~/.spin/config
  extract_to_file_if_defined key.json ~/.spin/key.json

  rewrite_spin_key_path
fi

popd
rm -rf $TEMP_DIR

if [ "$CI" != true ]; then
  # Update the generated markdown pages.
  ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_landing_page.sh
fi
