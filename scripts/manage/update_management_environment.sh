#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

pushd ~/cloudshell_open/spinnaker-for-gcp/scripts/manage

# We re-generate landing_page_expanded.md all the time; we should not stash those changes.
git checkout -- landing_page_expanded.md

GIT_STASH_COUNT_BEFORE=$(git stash list | wc -l)

bold "Stashing local changes..."
git stash save "Stashed by update_management_environment.sh"

GIT_STASH_COUNT_AFTER=$(git stash list | wc -l)

if [ "$GIT_STASH_COUNT_AFTER" != $GIT_STASH_COUNT_BEFORE ]; then
  bold "Changes were stashed. You will need to manually reapply any stashed changes after the update."
fi

git checkout master
git pull origin master

# New properties have been added over time and we want to ensure these are declared in the properties file.
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/add_missing_properties.sh

# Update the GKE Application details view.
~/cloudshell_open/spinnaker-for-gcp/scripts/manage/deploy_application_manifest.sh

# Update the generated markdown pages.
./update_landing_page.sh

# Refresh the tutorial view.
./update_console.sh

popd