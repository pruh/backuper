#!/bin/bash

# This script will check free space left and exit with error if it is below threshold

source "$(dirname $0)/conf.sh"

# Threshold in GB
FREE_SPACE_THRESHOLD=1000

if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ ! -d $REMOTE_ROOT ]"; then
  echo "no folder to check space" >&2
  exit 1
fi

free_space=$(ssh ${RUSER}@${RHOST} $SSH_OPTS \
  "df -BG $REMOTE_ROOT | tail -1 | awk '{print \$4}' | sed 's/[^0-9]//g'")

echo "backup disk space left: $free_space gigabytes"

if [ $free_space -lt $FREE_SPACE_THRESHOLD ]; then
  echo "backup disk space low: $free_space gigabytes" >&2
  exit 1
fi
