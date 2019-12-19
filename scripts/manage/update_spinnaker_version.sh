#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

bold "Updating Spinnaker to version $SPINNAKER_VERSION..."

~/hal/hal config version edit --version $SPINNAKER_VERSION
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/push_and_apply.sh
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/update_landing_page.sh
