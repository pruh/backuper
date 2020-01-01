#!/bin/bash

# The purpose of this script is to check and add if needed server key
# to ~/.ssh/known_hosts and check that connection with selected user
# using SSH is possible

# Common constants
source "$(dirname $0)/conf.sh"

# Backup host key algorithm that we want to use
# this name will be used in ssh-keygen and ssh-keyscan commands:
# ssh-keyscan man AND ssh-keygen man
KEY_TYPE=ecdsa
# and this name will be used in ssh command: ssh_config man
FULL_KEY_TYPE=ecdsa-sha2-nistp256

# To check which algorithm is supported by the server,
# run this command on it
# cat /etc/ssh/ssh_host_*.pub

ssh-keygen -F $RHOST -t $KEY_TYPE &> /dev/null
if [ $? -eq 0 ]; then
  echo 'Backup host is already known'
  exit
fi

if [ ! -e ~/.ssh/ ]; then
  echo 'Creating .ssh folder'
  mkdir -m 700 ~/.ssh/
fi

ssh-keyscan -H -t $KEY_TYPE $RHOST >> ~/.ssh/known_hosts 2> /dev/null
ssh-keygen -F $RHOST -t $KEY_TYPE &> /dev/null
if [ $? -ne 0 ]; then
  echo 'Failed to add key'
  exit 1
fi

ssh ${RUSER}@${RHOST} $SSH_OPTS -q exit || {
  echo "Cannot connect to $RHOST with $RUSER user" >&2
  exit 1
}

echo "$RHOST key successfully added to 'known_hosts'"
