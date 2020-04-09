#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

if [ "$CI" == true ]; then
  HAL_PARENT_DIR=$PARENT_DIR
else
  HAL_PARENT_DIR=$HOME
fi

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/service_utils.sh

# Please note, rewritable key paths are in both push_config.sh and restore_config_utils.sh
rewrite_hal_key_paths() {
  REWRITABLE_KEYS=(kubeconfigFile jsonPath jsonKey passwordFile path templatePath tokenFile \
                   usernamePasswordFile sshPrivateKeyFilePath sshKnownHostsFilePath trustStore credentialPath)
  for k in "${REWRITABLE_KEYS[@]}"; do
    grep $k .hal/config &> /dev/null
    FOUND_TOKEN=$?

    if [ "$FOUND_TOKEN" == "0" ]; then
      bold "Rewriting $k path to reflect local user '$USER' on Cloud Shell VM..."
      sed -i "s/$k: \/home\/spinnaker/$k: \/home\/$USER/" .hal/config
    fi
  done
}

copy_hal_subdirs() {
  DIRS=(credentials profiles service-settings)

  for p in "${DIRS[@]}"; do
    for f in $(find .hal/*/$p -prune 2> /dev/null); do
      SUB_PATH=$(echo $f | rev | cut -d '/' -f 1,2 | rev)
      mkdir -p $HAL_PARENT_DIR/.hal/$SUB_PATH
      cp -RT .hal/$SUB_PATH $HAL_PARENT_DIR/.hal/$SUB_PATH
    done
  done  
}

rewrite_spin_key_path() {
  bold "Rewriting key path in $HOME/.spin/config to reflect local user '$USER' on Cloud Shell VM..."
  sed -i "s/^    serviceAccountKeyPath: .*/    serviceAccountKeyPath: \"\/home\/$USER\/.spin\/key.json\"/" $HOME/.spin/config
}
