#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR="$HOME/cloudshell_open"

$PARENT_DIR/spinnaker-for-gcp/scripts/manage/check_duplicate_dirs.sh || exit 1

cloudshell launch-tutorial ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
