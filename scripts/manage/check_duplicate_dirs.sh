#!/usr/bin/env bash

bold() {
  echo "$(tput bold)""$*" "$(tput sgr0)";
}

if [ -d "$HOME/cloudshell_open" ]; then
  MATCHING_REPO_DIRS=$(find ~/cloudshell_open -maxdepth 1 -regex '.*/spinnaker-for-gcp-.+')

  if [ "$MATCHING_REPO_DIRS" ]; then
    NUM_EXTRANEOUS_DIRS=$(echo "$MATCHING_REPO_DIRS" | wc -l)

    bold "It looks like you might have cloned the spinnaker-for-gcp repository into" \
         "more than one directory. If you have any directories other than" \
         "$HOME/cloudshell_open/spinnaker-for-gcp that contain the repo, delete" \
         "them in order to avoid unwanted behavior."
    bold "If you have any directory that starts with spinnaker-for-gcp-*, even if" \
         "it doesn't contain a clone of the repo, you have to delete or move that" \
         "in order for this script to run."
    bold "Conflicting directories:"
    bold "$MATCHING_REPO_DIRS"
    bold "All Spinnaker for GCP commands are required to be run within the" \
         "~/cloudshell_open/spinnaker-for-gcp directory."

    exit 1
  fi
fi

if [ -d "$HOME/spinnaker-for-gcp" ]; then
  bold "It looks like the spinnaker-for-gcp repository was cloned into" \
       "~/spinnaker-for-gcp. The current target location for the cloned repo" \
       "is ~/cloudshell_open/spinnaker-for-gcp. If you have any directories other" \
       "than $HOME/cloudshell_open/spinnaker-for-gcp that contain the repo," \
       "delete them in order to avoid unwanted behavior."
  bold "All Spinnaker for GCP commands are required to be run within the" \
       "~/cloudshell_open/spinnaker-for-gcp directory."
  bold "The easiest way to resolve this is to:"
  bold "  - Delete the ~/spinnaker-for-gcp directory."
  bold "  - Exit out of Cloud Shell."
  bold "  - Click once more on the link you used to reach Cloud Shell (might be in" \
       "GCP Marketplace, might be in the Application details view in GKE)."

  exit 1
fi
