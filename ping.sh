#!/bin/bash

if [ "$1" == "" ]; then
  echo Error: No profile specified
  exit 1
elif [ ! -f "$1" ]; then
  echo Error: Profile not found: $1
  exit 1
fi

source $1

function send_message() {
  local message=$1
  local api_url=https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
  local time=$(date "+%F %T")
  [ "$PING_PORT" != "" ] && message="$message on port $PING_PORT"
  local payload='{"chat_id":'$TELEGRAM_CHATID',"text":"'$HOSTNAME' @'$time'\n'$message'"}'
  curl -X POST -H "Content-Type:application/json" -d "$payload" $api_url
}

[ "$PING_PORT" == "" ] && ping $PING_HOST -c 1 || (echo >/dev/tcp/$PING_HOST/$PING_PORT) &>/dev/null
if [ $? == 0 ]; then
  if [ "$last_notified_at" != "" ]; then
    send_message "Successfully pinged $PING_HOST"
    sed -i "/^last_notified_at=.*/d" "$1"
  fi
  exit 0
fi

current_timestamp=$(date +%s)
if [ "$last_notified_at" == "" ]; then
  message="Unable to ping $PING_HOST"
elif [[ "$NOTIFICATION_COOLDOWN" == "" || "$current_timestamp - $last_notified_at" -ge $NOTIFICATION_COOLDOWN ]]; then
  message="Still unable to ping $PING_HOST"
fi

if [ "$message" != "" ]; then
  send_message "$message"
  echo "last_notified_at=$current_timestamp" >> "$1"
fi
