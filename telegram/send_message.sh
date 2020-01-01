#!/bin/bash

# Send message to already created telegram chat using chat id.
# If -s is specified, then message will be sent silently.

# TODO add real chat id
CHATID="CHAT_ID"
# TODO add real bot token
TOKEN="BOT_TOKEN"
TIME="10"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

silent=false
while getopts ":s" opt; do
  case $opt in
    s)
      silent=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

shift $((OPTIND-1))

curl -s \
  -X POST $URL \
  --max-time $TIME \
  -F "chat_id=$CHATID" \
  -F "disable_web_page_preview=true" \
  -F "disable_notification=$silent" \
  -F "text=$1" \
  > /dev/null