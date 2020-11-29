#!/usr/bin/env bash

HALYARD_POD=spin-halyard-0

# TODO(duftler): Use --wait-for-completion?
kubectl exec $HALYARD_POD -n halyard -- bash -c 'hal deploy apply'

scripts/manage/deploy_application_manifest.sh
