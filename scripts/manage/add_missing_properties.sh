#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

PROPERTIES_FILE=$PARENT_DIR/spinnaker-for-gcp/scripts/install/properties

add_property_if_missing() {
  if [ -z "$(grep "export $1=" $PROPERTIES_FILE)" ]; then
    bold "Adding declaration of $1 to $PROPERTIES_FILE..."

    echo >> $PROPERTIES_FILE
    echo "$2" >> $PROPERTIES_FILE
  fi
}


read -r -d '' CSR_PROPERTY_DECLARATION  <<EOL
# If CSR repo does not exist, it will be created.
export CONFIG_CSR_REPO=\$DEPLOYMENT_NAME-config
EOL

add_property_if_missing CONFIG_CSR_REPO "$CSR_PROPERTY_DECLARATION"

add_property_if_missing NETWORK_PROJECT "export NETWORK_PROJECT=\$PROJECT_ID"
add_property_if_missing NETWORK_REFERENCE "export NETWORK_REFERENCE=projects/\$NETWORK_PROJECT/global/networks/\$NETWORK"
add_property_if_missing SUBNET_REFERENCE "export SUBNET_REFERENCE=projects/\$NETWORK_PROJECT/regions/\$REGION/subnetworks/\$SUBNET"
