#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source scripts/install/properties

bold "Updating Spinnaker to version $SPINNAKER_VERSION..."

~/hal/hal config version edit --version $SPINNAKER_VERSION
scripts/manage/push_and_apply.sh
scripts/manage/update_landing_page.sh
