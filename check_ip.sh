#!/bin/bash

if [ "$1" == "" ]; then
  echo Error: No profile specified
  exit 1
elif [ ! -f "$1" ]; then
  echo Error: Profile not found: $1
  exit 1
fi

source $1

current_ip=$(curl -s ifconfig.me)
[ "$recorded_ip" == "$current_ip" ] && exit 0

time=$(date "+%F %T")
api_url=https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
message="$HOSTNAME @$time\nPublic IP address changed to $current_ip"
payload='{"chat_id":'$TELEGRAM_CHATID',"text":"'$message'"}'
curl -X POST -H "Content-Type:application/json" -d "$payload" $api_url

sed -i "s/^recorded_ip=.*/recorded_ip=$current_ip/" "$1"
