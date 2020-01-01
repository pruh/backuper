#!/bin/bash

# This script logs its input to proper files adding time and PID
# and additionally uses telegram to send errors to.
#
# Usually all you have to do to use logger is to add the following lines:
# exec > >("path_to_logs_eater/logs_eater.sh" -f log_file_path)
# exec 2> >("path_to_logs_eater/logs_eater.sh" -s -f log_file_path)
#
# log file will be created if there is enough priviliges, otherwise
# create it beforehand

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

format_date() {
  date '+%Y/%m/%d %H:%M:%S'
}

severity=0
while getopts "sf:" opt; do
  case $opt in
    s)
      severity=1
      ;;
    f)
      log_file="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [ -z "$log_file" ]; then
  echo 'log file should be specified using -f option' >&2
  exit 1
fi

log_to_file=true
if [ ! -f "$log_file" ]; then
  mkdir -p $(dirname "$log_file") && touch "$log_file" || {
    echo "Cannot create log file, file logging will be skipped" >&2
    log_to_file=false
  }
fi

while read line; do
  if [ "$log_to_file" = true ]; then
    echo "$(format_date) [$$] $line" >> "$log_file"
  fi

  if [ $severity -eq 1 ]; then
    "$DIR/../telegram/send_message.sh" "ERROR on $HOSTNAME: $line"
  fi
done
