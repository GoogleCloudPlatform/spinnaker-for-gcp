#!/usr/bin/env bash

curl -LO https://storage.googleapis.com/spinnaker-artifacts/spin/$(curl -s https://storage.googleapis.com/spinnaker-artifacts/spin/latest)/linux/amd64/spin

chmod +x spin
mv spin ~

grep -q '^alias spin=~/spin' ~/.bashrc || echo 'alias spin=~/spin' >> ~/.bashrc

mkdir -p ~/.spin

cat >~/.spin/config <<EOL
gate:
  endpoint: http://localhost:8080/gate
EOL
