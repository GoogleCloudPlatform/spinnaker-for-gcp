#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

PROPERTIES_FILE=~/spinnaker-for-gcp/scripts/install/properties

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
