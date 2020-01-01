#!/bin/bash

# Working dir
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Folders where to place lock and ssh control files
SSH_CTRL_DIR="/var/tmp/backuper"
LOCKS_DIR="/var/lock/backuper"

# SSH connection share params
SSH_CTRL_OPTS="-o ControlMaster=auto -o ControlPath=${SSH_CTRL_DIR}/%L-%r@%h:%p -o ControlPersist=5m"

# SSH key to use
# TODO replace with path to ssh private key
SSH_KEY_PATH=/home/user/.ssh/id_rsa

SSH_OPTS="$SSH_CTRL_OPTS -i $SSH_KEY_PATH"

# Remote user
# TODO replace with backup user on remote
RUSER=backupuser

# Remote host
# TODO replace with remote backup server address
RHOST=192.168.1.1

# TODO replace with root folder for backups on remote server
REMOTE_ROOT="/backups/"

# Target root
HOST_BACKUPS_ROOT="$REMOTE_ROOT/${HOSTNAME}"

# change working dir to current, so tmp files will be stored only here
cd "$DIR"

create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -m 777 -p "$1" || {
      echo "Cannot create temp dir for ssh $1" >&2
      exit 1
    }
  fi
}

create_dir "$SSH_CTRL_DIR"
create_dir "$LOCKS_DIR"
