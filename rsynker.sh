#!/bin/bash

# Set constants
SOURCE_DIR="$HOME/example/bin"
BACKUP_PORT=22
BACKUP_DIR="user@example.net:/home/user/sample"
LOG_FILE=/var/log/rsynker/`date "+%Y-%m"`.log
EXCLUDE=

# ========================================
# Do not change any code beyond this point
# ========================================

switch=$1

basename=`basename "$0"`
process_count=$(pgrep -c $basename)
[ $process_count -gt 1 ] && exit 0

excludes=$(cat "$0"|grep ^EXCLUDE=|grep -v ^EXCLUDE=$|sed s/^EXCLUDE/--exclude/)
if [[ "$switch" == -n || "$switch" == --dry-run ]]; then
  rsync -avns --delete -e "ssh -p $BACKUP_PORT" $excludes "$SOURCE_DIR" "$BACKUP_DIR"
  exit 0
elif [ "$switch" != "" ]; then
  echo Error: Invalid switch: $switch
  exit 1
fi

first_item=$(rsync -avns --delete -e "ssh -p $BACKUP_PORT" $excludes "$SOURCE_DIR" "$BACKUP_DIR"|head -n2|tail -n1)
[ "$first_item" == "" ] && exit

rsync -as --delete -e "ssh -p $BACKUP_PORT" --log-file="$LOG_FILE" $excludes "$SOURCE_DIR" "$BACKUP_DIR"
