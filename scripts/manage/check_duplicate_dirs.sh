#!/usr/bin/env bash

bold() {
  echo "$(tput bold)""$*" "$(tput sgr0)";
}

MATCHING_REPO_DIRS=$(find ~ -maxdepth 1 -regex '.*/spinnaker-for-gcp-.+')

if [ "$MATCHING_REPO_DIRS" ]; then
  NUM_EXTRANEOUS_DIRS=$(echo "$MATCHING_REPO_DIRS" | wc -l)

  bold "It looks like you might have cloned the spinnaker-for-gcp repository into" \
       "more than one directory. If you have any directories other than" \
       "$HOME/spinnnaker-for-gcp/ that contain the repo, delete them in order to" \
       "avoid unwanted behavior."
  bold "If you have any directory that starts with spinnaker-for-gcp-*, even if" \
       "it doesn't contain a clone of the repo, you have to delete or move that" \
       "in order for this script to run."
  bold "Conflicting directories:"
  bold "$MATCHING_REPO_DIRS"
  bold "All Spinnaker for GCP commands are required to be run within the ~/spinnaker-for-gcp" \
       "directory."

  exit 1
fi
