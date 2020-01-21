#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

bold "Updating halyard daemon..."

if [ -z "$HALYARD_VERSION" ]; then
	bold "HALYARD_VERSION not set..."
	exit 1
fi

kubectl set image statefulset spin-halyard -n halyard halyard-daemon=gcr.io/spinnaker-marketplace/halyard:$HALYARD_VERSION
