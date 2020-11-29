#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

[ -z "$PROPERTIES_FILE" ] && PROPERTIES_FILE="$PARENT_DIR/scripts/install/properties"

if [ -f "$PROPERTIES_FILE" ]; then
    source "$PROPERTIES_FILE"
fi

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

has_service_enabled() {
  gcloud services list --project $1 \
    --filter="config.name:$2" \
    --format="value(config.name)"
}

check_for_command() {
  COMMAND_PRESENT=$(command -v $1)
  echo $COMMAND_PRESENT
}

check_for_required_binaries() {
  REQUIRED_BINARIES=(git gcloud jq kubectl)

  MISSING_BINARIES=""
  for b in "${REQUIRED_BINARIES[@]}"; do
    BINARY_PATH=$(check_for_command $b)
    if [ -z "$BINARY_PATH" ]; then
      if [ -z $MISSING_BINARIES ]; then
        MISSING_BINARIES="$b"
      else 
        MISSING_BINARIES="$MISSING_BINARIES, $b"
      fi
    fi
  done

  if [ -n "$MISSING_BINARIES" ]; then 
    bold "The following command(s) are required for setup but were not found: $MISSING_BINARIES"
    exit 1
  fi
}

check_for_shared_vpc() {
  if [ "$PROJECT_ID" != "$NETWORK_PROJECT" -a "$1" = true ]; then
    bold "Automated setup of Spinnaker for GCP with a Shared VPC host project is currently unsupported. To proceed, continue the setup in Cloud Shell."
    exit 1
  fi
}

#  Stupid function
#    $0 is the name of the calling function i.e. '/home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh'
#    PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)
#      jeremy_berg@cloudshell:scripts/install$
#        dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh | rev | cut -d '/' -f 4- | rev
#        /home/jeremy_berg/cloudshell_open

#        $(realpath $0) -> expands the ~ and $<vars> to give the absolute path
# jeremy_berg@cloudshell:scripts/install$ realpath scripts/install/setup_properties.sh
# /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh

#        dirname $(realpath $0) -> simply removes everything after the last '/' irrespective of the slash, including the slash
#        rev does a character reversal
#        cut -d '/' -f 4- is wacky, the '-f 1' parameter is a one-based-reference to the left of the '/' and returns the input,(seriously messed up)
#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/larry/a/b/c/setup_properties.sh | cut -d '/' -f 1-
#/home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/larry/a/b/c
#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/larry/a/b/c/setup_properties.sh
#/home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/larry/a/b/c
#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/larry/a/b/c/setup_properties.sh | cut -d '/' -f 1
#
# NOTE: this line implies that when you 'cut' something the '-f 1' item is the empty item at the left-beginning

#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh
#/home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install
#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/
#/home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts
#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install
#/home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts

#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh | rev
#llatsni/stpircs/pcg-rof-rekannips/nepo_llehsduolc/greb_ymerej/emoh/

#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh | rev | cut -d '/' -f 4-
#nepo_llehsduolc/greb_ymerej/emoh/

#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh | rev | cut -d '/' -f 1-
#llatsni/stpircs/pcg-rof-rekannips/nepo_llehsduolc/greb_ymerej/emoh/

#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh | rev | cut -d '/' -f 2-
#stpircs/pcg-rof-rekannips/nepo_llehsduolc/greb_ymerej/emoh/

#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh | rev | cut -d '/' -f 1
#llatsni

#jeremy_berg@cloudshell:scripts/install$ dirname /home/jeremy_berg/cloudshell_open/spinnaker-for-gcp/scripts/install/setup_properties.sh | rev | cut -d '/' -f 4- | rev
#/home/jeremy_berg/cloudshell_open
