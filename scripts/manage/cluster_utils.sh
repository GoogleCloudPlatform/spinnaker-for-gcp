#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

check_for_existing_cluster() {
  bold "Checking for existing cluster $GKE_CLUSTER..." >&2

  CLUSTER_EXISTS=$(gcloud beta container clusters list --project $PROJECT_ID \
    --filter="name=$GKE_CLUSTER" \
    --format="value(name)")

  echo $CLUSTER_EXISTS
}
