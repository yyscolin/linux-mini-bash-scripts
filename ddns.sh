#!/bin/bash

TELEGRAM_API_URL=https://api.telegram.org

if [ "$1" != "" ]; then
  profile="$1"
else
  echo Error: No profile specified
  exit 1
fi

DIR=$(dirname "$(realpath "$0")")

function print() {
  message="$(date "+%F %T") $1"

  # Output to terminal
  echo -e "$message"

  # Output to log file
  [ ! -d "$DIR/logs" ] && mkdir "$DIR/logs"
  echo -e "$message" >> "$DIR/logs/ddns.$profile.log"

  # Output to Telegram
  if [ "$TG_TOKEN" != "" ] && [ "$TG_CHATID" != "" ]; then
    api_url=$TELEGRAM_API_URL/bot$TG_TOKEN/sendMessage
    payload='{"chat_id":'$TG_CHATID',"text":"'$message'"}'
    curl -X POST -H "Content-Type:application/json" -d "$payload" $api_url
  fi
}

function source_env() {
  if [ -f "$DIR/ddns.$profile.env" ]; then
    source "$DIR/ddns.$profile.env"
  else
    echo "Error: File not found: $DIR/ddns.$profile.env"
    exit 1
  fi
}

source_env

CF_API_URL=https://api.cloudflare.com/client/v4

function check_ip() {
  source_env
  ip_current=$(curl -s ifconfig.me)

  # IP address given by ifconfig.me is not in a valid IPv4 format
  if [[ ! "$ip_current" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    if [ "$ip_cached" != "NOT_IPV4" ]; then
      print "Error: Response from ipconfig.me does not match IPv4 format:"
      print "$ip_current"
      sed -i "s/^ip_cached=.*/ip_cached=NOT_IPV4/" "$DIR/ddns.$profile.env"
    fi
    return 1
  fi

  # IP address remains unchanged
  [ "$ip_current" == "$ip_cached" ] && return 0

  # IP address has changed, update Cloudflare
  if [ "$CF_TOKEN" != "" ] && [ "$CF_ZONE_ID" != "" ] && [ "$CF_RECORD_ID" != "" ] && [ "$CF_DNS_NAME" != "" ]; then
    api_response=$(curl -s -X PUT "$CF_API_URL/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
      -H "Authorization: Bearer $CF_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$CF_DNS_NAME\",\"content\":\"$ip_current\"}" && echo)
    print "Updating CloudFlare DNS record for $CF_DNS_NAME from \"$ip_cached\" to \"$ip_current\": $api_response"
  fi

  sed -i "s/^ip_cached=.*/ip_cached=$ip_current/" "$DIR/ddns.$profile.env"
}

while true; do
  check_ip
  sleep $CHECK_INTERVAL
done
