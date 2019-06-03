#!/usr/bin/env bash

pushd ~/spinnaker-for-gcp/scripts

source ./install/properties

if [ $DOMAIN_NAME = "$DEPLOYMENT_NAME.endpoints.$PROJECT_ID.cloud.goog" ]; then
  export TOP_PRIVATE_DOMAIN=$PROJECT_ID.cloud.goog
else
  export TOP_PRIVATE_DOMAIN=$DOMAIN_NAME
fi

cat expose/configure_iap.md | envsubst > expose/configure_iap_expanded.md

cloudshell launch-tutorial expose/configure_iap_expanded.md

popd
