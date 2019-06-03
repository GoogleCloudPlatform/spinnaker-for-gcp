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

HAL_USER=$(cat ~/hal/spinnaker/config/halyard-user)

if [ -z "$HAL_USER" ]; then
  echo >&2 "Unable to derive halyard user, likely a corrupted install. Aborting."
  exit 1
fi

sudo groupadd halyard || true
sudo groupadd spinnaker || true
sudo usermod -G halyard -a $HAL_USER || true
sudo usermod -G spinnaker -a $HAL_USER || true

sudo mkdir -p /var/log/spinnaker/halyard
sudo chown $HAL_USER:halyard /var/log/spinnaker/halyard
sudo chmod 755 /var/log/spinnaker /var/log/spinnaker/halyard

sudo HAL_USER=$HAL_USER ~/hal/update-halyard $@

retVal=$?
if [ $retVal == 13 ]; then
  exit 13
fi

mkdir -p ~/hal/log
sudo mv /usr/local/bin/hal ~/hal
sudo rm -rf ~/hal/halyard/ && sudo mv /opt/halyard ~/hal
sudo mv /usr/local/bin/update-halyard ~/hal

sed -i 's:^. /etc/bash_completion.d/hal:# . /etc/bash_completion.d/hal\n. ~/hal/hal_completion\nalias hal=~/hal/hal:' ~/.bashrc
sed -i s:/opt/halyard:~/hal/halyard:g ~/hal/hal
sed -i s:/var/log/spinnaker/halyard:~/hal/log:g ~/hal/hal
sudo sed -i s:/opt/spinnaker:~/hal/spinnaker:g ~/hal/halyard/bin/halyard
sed -i 's:rm -rf /opt/halyard:rm -rf ~/hal/halyard:g' ~/hal/update-halyard
sed -i "s:^  HAL_USER=.*$:  HAL_USER=$(cat ~/hal/spinnaker/config/halyard-user):g" ~/hal/update-halyard
sed -i s:/etc/bash_completion.d/hal:~/hal/hal_completion: ~/hal/update-halyard
