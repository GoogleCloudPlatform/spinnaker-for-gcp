#!/usr/bin/env bash

[ -z "$PARENT_DIR" ] && PARENT_DIR=$(dirname $(realpath $0) | rev | cut -d '/' -f 4- | rev)

$PARENT_DIR/spinnaker-for-gcp/scripts/manage/check_duplicate_dirs.sh || exit 1

cloudshell launch-tutorial ~/cloudshell_open/spinnaker-for-gcp/scripts/manage/landing_page_expanded.md
