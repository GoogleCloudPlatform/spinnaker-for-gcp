#!/usr/bin/env bash

source ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/service_utils.sh
select_spinnaker_kubernetes_context || exit $?

HALYARD_POD=spin-halyard-0

# TODO(duftler): Use --wait-for-completion?
kubectl exec $HALYARD_POD -n halyard -- bash -c 'hal deploy apply'

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/deploy_application_manifest.sh
