#!/usr/bin/env bash

pushd ~/spinnaker-for-gcp/scripts

source ./install/properties

cat expose/configure_iap.md | envsubst > expose/configure_iap_expanded.md

cloudshell launch-tutorial expose/configure_iap_expanded.md

popd
