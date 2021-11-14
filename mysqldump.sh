#!/bin/bash

if ! command -v 7z &>/dev/null; then
    echo Error: Required package missing: p7zip-full
    exit 1
fi

if ! command -v mysqldump &>/dev/null; then
    echo Error: Required package missing: mysql-client-8.0
    exit 1
fi

if [ "$1" == "" ]; then
  echo Error: No profile specified
  exit 1
elif [ ! -f "$1" ]; then
  echo Error: Profile not found: $1
  exit 1
fi

source $1

backup_name=$BACKUP_NAME.$(date +%Y-%m-%d.%H%M%S)

cd /tmp
mysqldump --defaults-extra-file="$MYSQL_CONFIG" --hex-blob $BACKUP_DATABASE > "$backup_name.sql" || exit 1

tar -cf "$backup_name.tar" "$backup_name.sql" --remove-files
if [ $? -ne 0 ]; then
    rm "$backup_name.sql"
    echo Error: tar process failed
    exit 1
fi

7z a -sdel -p$ZIP_PASSWORD "$BACKUP_FOLDER/$backup_name.tar.7z" "$backup_name.tar" &>/dev/null
if [ $? -ne 0 ]; then
    rm "$backup_name.tar"
    echo Error: 7z compression failed
    exit 1
fi
