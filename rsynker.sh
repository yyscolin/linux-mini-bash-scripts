#!/bin/bash

if [ "$1" == "" ]; then
  echo Error: No profile specified
  exit 1
elif [ ! -f "$1" ]; then
  echo Error: Profile not found: $1
  exit 1
fi

source $1

basename=`basename "$0"`
process_count=$(pgrep -cf "$basename $1")
[ $process_count -gt 1 ] && exit 0

excludes=$(cat "$1"|grep ^EXCLUDE=|grep -v ^EXCLUDE=$|sed s/^EXCLUDE/--exclude/)
if [ "$IS_DRYRUN" == true ]; then
  rsync -avns --delete -e "ssh -p $BACKUP_PORT" $excludes "$SOURCE_DIR" "$BACKUP_DIR"
  exit 0
fi

first_item=$(rsync -avns --delete -e "ssh -p $BACKUP_PORT" $excludes "$SOURCE_DIR" "$BACKUP_DIR"|head -n2|tail -n1)
[ "$first_item" == "" ] && exit

rsync -as --delete -e "ssh -p $BACKUP_PORT" --log-file="$LOG_FILE" $excludes "$SOURCE_DIR" "$BACKUP_DIR"
