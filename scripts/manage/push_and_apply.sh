#!/usr/bin/env bash

scripts/manage/push_config.sh || exit 1
scripts/manage/apply_config.sh
