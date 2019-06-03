#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/spinnaker-for-gcp/scripts/install/properties

bold "Updating halyard daemon..."

if [ -z "$HALYARD_VERSION"];
	bold "HALYARD_VERSION not set..."
	exit 1

kubectl set image statefulset spin-halyard -n halyard halyard-daemon=gcr.io/spinnaker-marketplace/halyard:$HALYARD_VERSION
