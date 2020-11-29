#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source scripts/install/properties

bold "Updating halyard daemon..."

if [ -z "$HALYARD_VERSION" ]; then
	bold "HALYARD_VERSION not set..."
	exit 1
fi

kubectl set image statefulset spin-halyard -n halyard halyard-daemon=us-docker.pkg.dev/spinnaker-community/docker/halyard:$HALYARD_VERSION
