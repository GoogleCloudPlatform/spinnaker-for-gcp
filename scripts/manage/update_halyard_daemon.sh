#!/usr/bin/env bash

source ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/service_utils.sh
source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

bold "Updating halyard daemon..."

if [ -z "$HALYARD_VERSION" ]; then
	bold "HALYARD_VERSION not set..."
	exit 1
fi

select_spinnaker_kubernetes_context || exit $?
kubectl set image statefulset spin-halyard -n halyard halyard-daemon=us-docker.pkg.dev/spinnaker-community/docker/halyard:$HALYARD_VERSION
