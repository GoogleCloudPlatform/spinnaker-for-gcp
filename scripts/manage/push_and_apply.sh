#!/usr/bin/env bash

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/push_config.sh || exit 1
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/apply_config.sh
