#!/usr/bin/env bash

bold() {
  echo ". $(tput bold)" "$*" "$(tput sgr0)";
}

source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

~/cloudshell_open/spinnaker-for-gcp/scripts/manage/check_project_mismatch.sh

bold "Locating Deck pod..."

DECK_POD=$(kubectl -n spinnaker get pods -l cluster=spin-deck,app=spin \
  -o=jsonpath='{.items[0].metadata.name}')

bold "Forwarding localhost port 8080 to 9000 on $DECK_POD..."

pkill -f 'kubectl -n spinnaker port-forward'
kubectl -n spinnaker port-forward $DECK_POD 8080:9000 > /dev/null 2>&1 &

# Query for static ip address as a signal that the Spinnaker installation is exposed via a secured endpoint.
export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

if [ "$IP_ADDR" ]; then
  bold "Are you sure you aren't intending to connect via the domain name instead? Asking since you have a static ip configured..."
fi
