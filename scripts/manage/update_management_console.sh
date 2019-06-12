#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

pushd ~/spinnaker-for-gcp/scripts/manage

# We re-generate landing_page_expanded.md all the time; we should not stash those changes.
git checkout -- landing_page_expanded.md

GIT_STASH_COUNT_BEFORE=$(git stash list | wc -l)

bold "Stashing local changes..."
git stash

GIT_STASH_COUNT_AFTER=$(git stash list | wc -l)

if [ "$GIT_STASH_COUNT_AFTER" != $GIT_STASH_COUNT_BEFORE ]; then
  bold "Changes were stashed. You will need to manually reapply any stashed changes after the update."
fi

git checkout master
git pull origin master

# Update the GKE Application details view.
~/spinnaker-for-gcp/scripts/manage/deploy_application_manifest.sh

# Update the generated markdown pages.
./update_landing_page.sh

# Refresh the tutorial view.
./update_console.sh

popd