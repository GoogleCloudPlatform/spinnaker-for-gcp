#!/usr/bin/env bash

HALYARD_DAEMON_PID_FILE=~/hal/halyard/pid

function kill_daemon() {
    pkill -F $HALYARD_DAEMON_PID_FILE
}

if [ -f "$HALYARD_DAEMON_PID_FILE" ]; then
    HALYARD_DAEMON_PID=$(cat $HALYARD_DAEMON_PID_FILE)

    set +e
    ps $HALYARD_DAEMON_PID &> /dev/null
    exit_code=$?
    set -e

    if [ "$exit_code" == "0" ]; then
        kill_daemon
    fi
fi

# Just in case the pid file doesn't match the daemon that's actually listening on the port.
pkill -f '/opt/halyard/lib/halyard-web' || true
pkill -f "$HOME/hal/halyard/lib/halyard-web" || true

curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh
sudo bash InstallHalyard.sh --user $USER -y $@

retVal=$?
if [ $retVal == 13 ]; then
  exit 13
fi

mkdir -p ~/hal/log
sudo mv /etc/bash_completion.d/hal ~/hal/hal_completion
sudo mv /usr/local/bin/hal ~/hal
sudo mv /usr/local/bin/update-halyard ~/hal
sudo rm -rf ~/hal/halyard/ && sudo mv /opt/halyard ~/hal
sudo rm -rf ~/hal/spinnaker/ && sudo mv /opt/spinnaker ~/hal

sed -i 's:^. /etc/bash_completion.d/hal:# . /etc/bash_completion.d/hal\n. ~/hal/hal_completion\nalias hal=~/hal/hal:' ~/.bashrc
sed -i s:/opt/halyard:~/hal/halyard:g ~/hal/hal
sed -i s:/var/log/spinnaker/halyard:~/hal/log:g ~/hal/hal
sudo sed -i s:/opt/spinnaker:~/hal/spinnaker:g ~/hal/halyard/bin/halyard
sed -i 's:rm -rf /opt/halyard:rm -rf ~/hal/halyard:g' ~/hal/update-halyard
sed -i "s:^  HAL_USER=.*$:  HAL_USER=$(cat ~/hal/spinnaker/config/halyard-user):g" ~/hal/update-halyard
sed -i s:/etc/bash_completion.d/hal:~/hal/hal_completion: ~/hal/update-halyard
