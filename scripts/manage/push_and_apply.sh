#!/usr/bin/env bash

~/spinnaker-for-gcp/scripts/manage/push_config.sh || exit 1
~/spinnaker-for-gcp/scripts/manage/apply_config.sh
