#!/bin/bash

DIR=$(dirname "$(realpath "$0")")
SCRIPT_NAME=$(basename "$0" | sed 's/\.[^.]*$//') # w/o directory or file ext

if [ "$1" == "" ]; then
  ENV_FILE="$DIR/$SCRIPT_NAME.env"
  LOG_FILE="$DIR/logs/$SCRIPT_NAME.log"
else
  ENV_FILE="$DIR/$SCRIPT_NAME.$1.env"
  LOG_FILE="$DIR/logs/$SCRIPT_NAME.$1.log"
fi

function print() {
  message="$(date "+%F %T") $1"

  # Output to terminal
  echo -e "$message"

  # Output to log file
  [ ! -d "$DIR/logs" ] && mkdir "$DIR/logs"
  echo -e "$message" >> "$LOG_FILE"

  # Output to Telegram
  if [ "$TG_TOKEN" != "" ] && [ "$TG_CHATID" != "" ]; then
    api_url=https://api.telegram.org/bot$TG_TOKEN/sendMessage
    payload='{"chat_id":'$TG_CHATID',"text":"'$message'"}'
    curl -X POST -H "Content-Type:application/json" -d "$payload" $api_url
  fi
}

function source_env() {
  if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
  else
    echo "Error: Env file not found: $ENV_FILE"
    exit 1
  fi
}

source_env

function check_ip() {
  source_env
  ip_current=$(curl -s ifconfig.me)

  # If failed to get a response from ifconfig.me
  if [ "$ip_current" == "" ]; then
    if [ "$error_cached" != "NO_REPLY" ]; then
      print "Error: Failed to get a response from ifconfig.me"
      sed -i "s/^error_cached=.*/error_cached=NO_REPLY/" "$ENV_FILE"
    fi
    return 1

  # IP address given is not in a valid IPv4 format
  elif [[ ! "$ip_current" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    if [ "$error_cached" != "NOT_IPV4" ]; then
      print "Error: Response from ipconfig.me does not match IPv4 format: $ip_current"
      sed -i "s/^error_cached=.*/error_cached=NOT_IPV4/" "$ENV_FILE"
    fi
    return 1
  fi

  sed -i "s/^error_cached=.*/error_cached=/" "$ENV_FILE"

  # IP address remains unchanged
  [ "$ip_current" == "$ip_cached" ] && return 0

  # IP address has changed, update Cloudflare
  if [ "$CF_TOKEN" != "" ] && [ "$CF_ZONE_ID" != "" ] && [ "$CF_RECORD_ID" != "" ] && [ "$CF_DNS_NAME" != "" ]; then
    api_response=$(curl -s \
      -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
      -H "Authorization: Bearer $CF_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$CF_DNS_NAME\",\"content\":\"$ip_current\"}" && echo)
    print "Updating CloudFlare DNS record for $CF_DNS_NAME from \"$ip_cached\" to \"$ip_current\": $api_response"
  fi

  sed -i "s/^ip_cached=.*/ip_cached=$ip_current/" "$ENV_FILE"
}

while true; do
  check_ip
  sleep $CHECK_INTERVAL
done
