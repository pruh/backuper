#!/bin/bash

# This script doesn't support passphrase typing for SSH key

source "$(dirname $0)/conf.sh"

exec > >("$DIR/../logs_eater/logs_eater.sh" -f /var/log/backuper/std.log)
exec 2> >("$DIR/../logs_eater/logs_eater.sh" -s -f /var/log/backuper/err.log)

if ! [ $(id -u) = 0 ]; then
  echo "Must be root to run $0" >&2
  exit 1
fi

hash rsync 2>/dev/null || {
  echo "rsync should be installed on $HOSTNAME to make backups" >&2
  exit 1
}

bash ./connection_checker.sh || {
  echo "Failed to connect to $RHOST" >&2
  exit 1
}

# TODO check disk health or something else

bash "$DIR/space_check.sh" || {
  exit 1
}

# ugly construction to read file into a variable and then read it line by line because
# ssh in backup script consumes stdin and loops cannot be used here:
# http://stackoverflow.com/a/13800476/836413
csv=$(<"$1")

IFS=$'\n'
for line in $csv; do
  name=$(echo "$line" | cut -d, -f1)
  name="$(echo -e "$name" | sed -e 's/^[[:space:]]*//')"
  if [ -z "$name" ] || [ "${name:0:1}" = \# ]; then
    continue;
  fi

  localpath=$(echo "$line" | cut -d, -f2)

  "$DIR/make_backup.sh" "$name" "$localpath" &&
    "$DIR/verify_backup.sh" "$name" "$localpath" && {
      if [ ! -z $finished ]; then
        finished+=", "
      fi

      finished+="$name"
    }
done

if [ ! -z "$finished" ]; then
  "$DIR/../telegram/send_message.sh" -s "$HOSTNAME successfully backed up: $finished"
fi
