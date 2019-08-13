#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

~/spinnaker-for-gcp/scripts/manage/check_git_config.sh || exit 1

while getopts ":p:r:h:" options; do
  case $options in
    p ) PROJECT_ID=$OPTARG ;;
    r ) CONFIG_CSR_REPO=$OPTARG ;;
    h ) GIT_HASH=$OPTARG ;;
    \? ) bold "invalid option supplied: -$OPTARG"
  esac
done

EXAMPLE_COMMAND="'restore_backup_to_cloudshell.sh -p PROJECT -r REPOSITORY_NAME -h GIT_HASH'"

if [ -z "$PROJECT_ID" ]; then
  bold "Project id is required. $EXAMPLE_COMMAND"
  exit 1
fi

if [ -z "$CONFIG_CSR_REPO" ]; then
  bold "Cloud Source repository name is required. $EXAMPLE_COMMAND"
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
  bold "Cloud source repository $CONFIG_CSR_REPO not found"
  popd
  rm -rf $TEMP_DIR
  exit
fi

HASH_PREVIEW_LINK="https://source.cloud.google.com/$PROJECT_ID/$EXISTING_CSR_REPO/+/$GIT_HASH"

read -p ". $(tput bold)You are about to replace the configuration files in your cloudshell with the configuration at $HASH_PREVIEW_LINK . This step is not reversible. Do you wish to continue (Y/n)? $(tput sgr0)" yn
case $yn in
  [Yy]* ) ;;
  "" ) ;;
  * ) 
    popd
    rm -rf $TEMP_DIR
    exit
  ;;
esac

cd $CONFIG_CSR_REPO
git checkout $GIT_HASH &> /dev/null

# Remove local hal config so persistent config from backup can be copied into place.
bold "Removing $HOME/.hal..."
rm -rf ~/.hal

# Copy persistent config into place.
bold "Copying $CONFIG_CSR_REPO/.hal into $HOME/.hal..."

REWRITABLE_KEYS=(kubeconfigFile jsonPath jsonKey)
for k in "${REWRITABLE_KEYS[@]}"; do
  grep $k .hal/config &> /dev/null
  FOUND_TOKEN=$?

  if [ "$FOUND_TOKEN" == "0" ]; then
    bold "Rewriting $k path to reflect local user '$USER' on Cloud Shell VM..."
    sed -i "s/$k: \/home\/spinnaker/$k: \/home\/$USER/" .hal/config
  fi
done

# We want just these subdirs from the backup to be copied into place in ~/.hal.
DIRS=(credentials profiles service-settings)

for p in "${DIRS[@]}"; do
  for f in $(find .hal/*/$p -prune 2> /dev/null); do
    SUB_PATH=$(echo $f | rev | cut -d '/' -f 1,2 | rev)
    mkdir -p ~/.hal/$SUB_PATH
    cp -RT .hal/$SUB_PATH ~/.hal/$SUB_PATH
  done
done

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
remove_and_copy properties ~/spinnaker-for-gcp/scripts/install/properties 
remove_and_copy config.json ~/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/config.json
remove_and_copy index.js ~/spinnaker-for-gcp/scripts/install/spinnakerAuditLog/index.js
remove_and_copy landing_page_expanded.md ~/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md

remove_and_copy configure_iap_expanded.md ~/spinnaker-for-gcp/scripts/expose/configure_iap_expanded.md
remove_and_copy openapi_expanded.yml ~/spinnaker-for-gcp/scripts/expose/openapi_expanded.yml
mkdir -p ~/.spin
remove_and_copy config ~/.spin/config
remove_and_copy key.json ~/.spin/key.json

popd
rm -rf $TEMP_DIR

bold "Configuration applied. To diff this config with what was last deployed, go to https://source.cloud.google.com/$PROJECT_ID/$EXISTING_CSR_REPO/+/$GIT_HASH...master"
bold "To apply the halyard config changes to the cluster, run ~/spinnaker-for-gcp/scripts/manage/push_and_apply.sh. To apply changes in the properties file to your deployment, run ~/spinnaker-for-gcp/scripts/install/setup.sh"