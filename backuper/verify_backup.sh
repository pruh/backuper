#!/bin/bash

# Common constants
source "$(dirname $0)/conf.sh"

# Backup specific constants
source "$(dirname $0)/backup_conf.sh" "$1" "$2"

# in case of false positive pattern can be refined to check what actually changed (permissions, timestamp, etc.)
error_pattern="^[<>]"
warn_pattern="^\."

while read -r line; do
  if [[ "$line" =~ $error_pattern ]] || [[ "$line" =~ $warn_pattern ]]; then
    echo "'$line' has changed after '$NAME' backup finished" >&2
    exit 1
  fi
done < <(rsync -avHP --itemize-changes --dry-run -e "ssh $SSH_OPTS" \
  "$LOCAL_PATH" "${RUSER}@${RHOST}:$LINKS_BACKUP_PATH")
