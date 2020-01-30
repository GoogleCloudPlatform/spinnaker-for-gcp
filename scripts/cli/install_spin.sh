#!/usr/bin/env bash

curl -LO https://storage.googleapis.com/spinnaker-artifacts/spin/$(curl -s https://storage.googleapis.com/spinnaker-artifacts/spin/latest)/linux/amd64/spin

chmod +x spin
mv spin ~

grep -q '^alias spin=~/spin' ~/.bashrc || echo 'alias spin=~/spin' >> ~/.bashrc

mkdir -p ~/.spin

# If there is no properties file, generate a new ~/.spin/config relying on port-forwarding.
if [ ! -f "$HOME/cloudshell_open/spinnaker-for-gcp/scripts/install/properties" ]; then
  cat >~/.spin/config <<EOL
gate:
  endpoint: http://localhost:8080/gate
EOL

  exit 0
fi

source ~/cloudshell_open/spinnaker-for-gcp/scripts/install/properties

# Query for static ip address as a signal that the Spinnaker installation is exposed via a secured endpoint.
export IP_ADDR=$(gcloud compute addresses list --filter="name=$STATIC_IP_NAME" \
  --format="value(address)" --global --project $PROJECT_ID)

# Only re-generate ~/.spin/config if Spinnaker installation in unsecured. Otherwise, leave whatever is there.
# The ~/.spin/config will always be restored by pull_config.sh in any case.
if [ -z "$IP_ADDR" ]; then
  cat >~/.spin/config <<EOL
gate:
  endpoint: http://localhost:8080/gate
EOL
fi
