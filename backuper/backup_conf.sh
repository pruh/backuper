#!/bin/bash

# Backup name
NAME="$1"

# Folder to back up
LOCAL_PATH="$2"

# Root folder for $NAME backups
BACKUP_ROOT="${HOST_BACKUPS_ROOT}/$NAME"

# Folder name on remote to use for hardlinking
LINKS_FOLDER_NAME=current

# Backup folder that is a link to the latest backup
LINKS_BACKUP_PATH="${BACKUP_ROOT}/${LINKS_FOLDER_NAME}"

if [ -z "$NAME" ]; then
  echo "name should be set" >&2
  exit 1
fi

if [ "$#" -ne 2 ]; then
  echo "required name and path in arguments, currently there are $#: $@" >&2
  exit 1
fi

if [ ! -d "$LOCAL_PATH" ] && [ ! -f "$LOCAL_PATH" ]; then
  echo "$LOCAL_PATH does not exists, remove it from backup machine and backup list if it is no longer needed" >&2
  exit 1
fi
