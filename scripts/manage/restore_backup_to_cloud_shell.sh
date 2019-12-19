#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_git_config.sh || exit 1

while getopts ":p:r:h:" options; do
  case $options in
    p ) PROJECT_ID=$OPTARG ;;
    r ) CONFIG_CSR_REPO=$OPTARG ;;
    h ) GIT_HASH=$OPTARG ;;
    \? ) bold "Invalid option supplied: -$OPTARG"
  esac
done

EXAMPLE_COMMAND="'restore_backup_to_cloud_shell.sh -p PROJECT -r REPOSITORY_NAME -h GIT_HASH'"

if [ -z "$PROJECT_ID" ]; then
  bold "Project id is required. $EXAMPLE_COMMAND"
  exit 1
fi

if [ -z "$CONFIG_CSR_REPO" ]; then
  bold "Cloud Source Repository name is required. $EXAMPLE_COMMAND"
  exit 1
fi

if [ -z "$GIT_HASH" ]; then
  bold "Git commit hash is required. $EXAMPLE_COMMAND"
  exit 1
fi

TEMP_DIR=$(mktemp -d -t halyard.XXXXX)
pushd $TEMP_DIR

EXISTING_CSR_REPO=$(gcloud source repos list --format="value(name)" --filter="name=projects/$PROJECT_ID/repos/$CONFIG_CSR_REPO" --project=$PROJECT_ID)

if [ -n "$EXISTING_CSR_REPO" ]; then
  gcloud source repos clone $CONFIG_CSR_REPO --project=$PROJECT_ID
else
  bold "Cloud Source Repository $CONFIG_CSR_REPO not found"
  popd
  rm -rf $TEMP_DIR
  exit 1
fi

cd $CONFIG_CSR_REPO
HASH_CHECKOUT_ERROR=$(git branch --contains $GIT_HASH 2>&1 > /dev/null)

if [ -n "$HASH_CHECKOUT_ERROR" ]; then
  bold "Git commit hash: $GIT_HASH not found. Please enter a valid commit hash."
  popd
  rm -rf $TEMP_DIR
  exit 1
fi

HASH_PREVIEW_LINK="https://source.cloud.google.com/$PROJECT_ID/$EXISTING_CSR_REPO/+/$GIT_HASH"

read -p ". $(tput bold)You are about to replace the configuration files in your Cloud Shell with the configuration at:
. $HASH_PREVIEW_LINK
. This step is not reversible. Do you wish to continue (Y/n)? $(tput sgr0)" yn
case $yn in
  [Yy]* ) ;;
  "" ) ;;
  * ) 
    popd
    rm -rf $TEMP_DIR
    exit
  ;;
esac

git checkout $GIT_HASH &> /dev/null

# Remove local hal config so persistent config from backup can be copied into place.
bold "Removing $HOME/.hal..."
rm -rf ~/.hal

# Copy persistent config into place.
bold "Copying $CONFIG_CSR_REPO/.hal into $HOME/.hal..."

source ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/restore_config_utils.sh
rewrite_hal_key_paths

# We want just these subdirs from the backup to be copied into place in ~/.hal.
copy_hal_subdirs
cp .hal/config ~/.hal

remove_and_copy() {
  if [ -e $1 ]; then
    cp $1 $2
  elif [ -e $2 ]; then
    rm $2
  fi
}

cd deployment_config_files
bold "Restoring deployment config... from $CONFIG_CSR_REPO"
remove_and_copy properties ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties 
remove_and_copy config.json ~/cloudshell_open/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/config.json
remove_and_copy index.js ~/cloudshell_open/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/index.js

remove_and_copy configure_iap_expanded.md ~/cloudshell_open/spinnaker-for-gcp/scripts/expose/configure_iap_expanded.md
remove_and_copy openapi_expanded.yml ~/cloudshell_open/spinnaker-for-gcp/scripts/expose/openapi_expanded.yml
mkdir -p ~/.spin
remove_and_copy config ~/.spin/config
remove_and_copy key.json ~/.spin/key.json

if [ -e ~/.spin/config ]; then
  rewrite_spin_key_path
fi

popd
rm -rf $TEMP_DIR

bold "Configuration applied. To diff this config with what was last deployed, go to:"
bold "https://source.cloud.google.com/$PROJECT_ID/$EXISTING_CSR_REPO/+/$GIT_HASH...master"
bold "Note: If secure access via IAP is already configured, that access is left unchanged and remains secure."
bold "To apply the halyard config changes to the cluster, run:"
bold "~/cloudshell_open/spinnaker-for-gcp/scripts/manage/push_and_apply.sh"
