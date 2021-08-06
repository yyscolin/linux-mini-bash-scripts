#!/bin/bash

# Set constants
PING_HOST=example.com
PING_PORT=22
TELEGRAM_TOKEN=
TELEGRAM_CHATID=
NOTIFICATION_COOLDOWN=300

# ========================================
# Do not change any code beyond this point
# ========================================

last_notified_at=

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
    sed -i "s/^last_notified_at=.*/last_notified_at=/g" "$0"
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
  sed -i "s/^last_notified_at=.*/last_notified_at=$current_timestamp/g" "$0"
fi
