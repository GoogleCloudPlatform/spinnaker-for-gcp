#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR="$HOME"

source $PARENT_DIR/spinnaker-for-gcp/scripts/manage/service_utils.sh

rewrite_hal_key_paths() {
  REWRITABLE_KEYS=(kubeconfigFile jsonPath jsonKey passwordFile path templatePath)
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
      mkdir -p $PARENT_DIR/.hal/$SUB_PATH
      cp -RT .hal/$SUB_PATH $PARENT_DIR/.hal/$SUB_PATH
    done
  done  
}

rewrite_spin_key_path() {
  bold "Rewriting key path in $PARENT_DIR/.spin/config to reflect local user '$USER' on Cloud Shell VM..."
  sed -i "s/^    serviceAccountKeyPath: .*/    serviceAccountKeyPath: \"\/home\/$USER\/.spin\/key.json\"/" $PARENT_DIR/.spin/config  
}
