#!/bin/bash

TELEGRAM_TOKEN=
TELEGRAM_CHATID=
DISKS="/dev/sdX /dev/sdY"

# ========================================
# Do not change any code beyond this point
# ========================================

for disk in $DISKS; do
  status=$(smartctl -H $disk|grep "^SMART overall-health self-assessment test result:"|cut -d: -f2)
  [ $status != PASSED ] && message="$message\nSMART OHSA test result for $disk: $status"
done

if [ "$message" != "" ]; then
  time=$(date "+%F %T")
  api_url=https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage
  message="$HOSTNAME @$time$message"
  payload='{"chat_id":'$TELEGRAM_CHATID',"text":"'$message'"}'
  curl -X POST -H "Content-Type:application/json" -d "$payload" $api_url
fi
