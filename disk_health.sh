#!/bin/bash

if [ "$1" == "" ]; then
  echo Error: No profile specified
  exit 1
elif [ ! -f "$1" ]; then
  echo Error: Profile not found: $1
  exit 1
fi

source $1

for disk in $DISKS; do
  status=$(/usr/sbin/smartctl -H $disk|grep "^SMART overall-health self-assessment test result:"|cut -d: -f2)
  if [ "$status" == "" ]; then
    message="$message\nUnable to get SMART OHSA test result for $disk"
  elif [ $status != PASSED ]; then
    message="$message\nSMART OHSA test result for $disk: $status"
  fi
done

if [ "$message" != "" ]; then
  time=$(date "+%F %T")
  api_url=https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
  message="$HOSTNAME @$time$message"
  payload='{"chat_id":'$TELEGRAM_CHATID',"text":"'$message'"}'
  curl -X POST -H "Content-Type:application/json" -d "$payload" $api_url
fi
