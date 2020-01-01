#!/bin/bash

# Make a backup of a directory or a file.
# Name passed as $1 will be used as foldername
# on remote, so it must be unique.

# Common constants
source "$(dirname $0)/conf.sh"

# Backup specific constants
source "$(dirname $0)/backup_conf.sh" "$1" "$2"

# The target directory
BACKUP_FOLDER_NAME=backup-$(date "+%Y-%m-%d-%H-%M")

BACKUP_PATH="${BACKUP_ROOT}/${BACKUP_FOLDER_NAME}"

# Temp folder suffix
TEMP_SUFFIX=-incomplete

# Initial backup will be made to this folder, and it will be ranemd later
BACKUP_TEMP="${BACKUP_PATH}${TEMP_SUFFIX}"
# If backup item is file, then we need to specify that
# we want to make backup to remote folder and not to remote file
if [ -f "$LOCAL_PATH" ]; then
  BACKUP_TEMP="$BACKUP_TEMP/"
fi

# Number of last backups to keep
BACKUPS_LIMIT=30

remove_if_exists() {
  if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ -d '$1' ]"; then
    echo "Directory with name '$1' already exists - removing it"
    ssh ${RUSER}@${RHOST} $SSH_OPTS "rm -r '$1'"
  fi
}

get_latest_backup() {
  find_command="find '$1' -mindepth 1 -maxdepth 1 -type d -not -name '*$TEMP_SUFFIX' | sort -t- -k2 -r | head -1"
  ssh ${RUSER}@${RHOST} $SSH_OPTS "$find_command"
}

recreate_current() {
  echo "relinking '$1' to '$2'"
  ssh ${RUSER}@${RHOST} $SSH_OPTS "rm -f '$2' && ln -s '$1' '$2'"
}

ensure_prev_backup() {
  if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ ! -d '$1' ]"; then
    echo 'do not try to find previous backup - root directory does not exist'
    return
  fi

  if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ -d '$2' ]"; then
    echo 'previous backup directory exists'
    return
  fi

  echo 'previous backup not found, trying to relink'

  prev_last=$(get_latest_backup "$1")
  if [[ -z "$prev_last" ]]; then
    echo 'backup for relinking not found'
    return
  fi

  if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ -d '$prev_last' ]"; then
    echo "found new previous backup: '$prev_last'"
    recreate_current "$prev_last" "$2"
  else
    echo 'backup for relinking not found'
  fi
}

create_if_not_exists() {
  if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ ! -d '$1' ]"; then
    create "$1"
  fi
}

create() {
  echo "creating direcotry '$1'"
  ssh ${RUSER}@${RHOST} $SSH_OPTS "mkdir -p '$1'"
}

move_folder() {
  echo "moving temp folder '$1' to '$2'"
  ssh ${RUSER}@${RHOST} $SSH_OPTS "mv '$1' '$2'"
}

remove_old() {
  find_command_base="find '$1' -mindepth 1 -maxdepth 1 -type d -not -name '*$TEMP_SUFFIX'"
  count=$(ssh ${RUSER}@${RHOST} $SSH_OPTS "$find_command_base | wc -l")
  if [[ $count -le $BACKUPS_LIMIT ]]; then
    echo "there are $count out of allowed $BACKUPS_LIMIT backups - no need to delete"
    return
  fi

  echo "there are $count out of allowed $BACKUPS_LIMIT backups - need to remove $((count - $BACKUPS_LIMIT))"

  ssh ${RUSER}@${RHOST} $SSH_OPTS \
    "$find_command_base | sort -t- -k2 -r | tail -n +$(($BACKUPS_LIMIT+1)) | xargs rm -r"
}

check_exit_code() {
  exit_code=$?
  if [[ $exit_code -gt 0 ]]; then
    echo "$1, code: $exit_code" >&2
    exit $exit_code
  fi
}

set_lock() {
  lockfile="$LOCKS_DIR/.${NAME}-backup.lock"

  if [ -e "$lockfile" ]; then
    echo "lockfile: $lockfile exists, skipping $NAME backup" >&2
    exit 1
  fi

  touch "$lockfile"
  echo "started at `date +%Y-%m-%dT%H:%M:%S`" >> "$lockfile"
  trap "echo \"removing lockfile $lockfile\"; rm '$lockfile'" EXIT
  echo "lockfile $lockfile created"
}

check_temp_dirs() {
  find_command="find '$1' -mindepth 1 -maxdepth 1 -type d -name '*$TEMP_SUFFIX' | wc -l"
  if [[ $(ssh ${RUSER}@${RHOST} $SSH_OPTS "$find_command") -gt 0 ]]; then
    echo "there are temp dirs in $1" >&2
  fi
}

is_first_backup() {
  if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ -d '$1' ]"; then
     # 1 = false
    return 1
  else
    # 0 = true
    return 0
  fi
}

main() {
  echo "$NAME backup started at $(date '+%Y-%m-%dT%H:%M:%S')"

  set_lock

  if is_first_backup "$BACKUP_ROOT"; then
    create "$BACKUP_ROOT"
  else
    remove_if_exists "$BACKUP_PATH"
    remove_if_exists "$BACKUP_TEMP"

    check_temp_dirs "$BACKUP_ROOT"

    ensure_prev_backup "$BACKUP_ROOT" "$LINKS_BACKUP_PATH"

    # find if previous backup exists, so it can be used for hard linking
    if ssh ${RUSER}@${RHOST} $SSH_OPTS "[ -d '$LINKS_BACKUP_PATH' ]"; then
      echo 'using previous backup for hard linking'
      lnk_opts="--link-dest=$LINKS_BACKUP_PATH"
    else
      echo 'nothing to use for hard linking'
    fi
  fi

  rsync -avhP -e "ssh $SSH_OPTS" \
    $lnk_opts \
    $LOCAL_PATH \
    ${RUSER}@${RHOST}:$BACKUP_TEMP

  check_exit_code "$NAME backup failed when sending files to remote"

  move_folder "$BACKUP_TEMP" "$BACKUP_PATH" \
    && recreate_current "$BACKUP_PATH" "$LINKS_BACKUP_PATH"

  check_exit_code "$NAME backup failed when moving temp folder and relinking last backup"

  remove_old "$BACKUP_ROOT"

  check_exit_code "$NAME backup failed when cleaning remote from old backups"

  echo "backup finished at $(date +%Y-%m-%dT%H:%M:%S)"
}

main "$@"
