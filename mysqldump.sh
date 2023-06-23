#!/bin/bash

if ! command -v 7z &>/dev/null; then
  echo Error: Required package missing: p7zip-full
  exit 1
fi

if ! command -v mysqldump &>/dev/null; then
  echo Error: Required package missing: mysql-client-8.0
  exit 1
fi

source $1

if [ "$1" == "" ]; then
  echo Error: No profile specified
  exit 1
elif [ ! -f "$1" ]; then
  echo Error: Profile not found: $1
  exit 1
elif [ -z "$BACKUP_NAME" ]; then
  echo Error: Option must be set: BACKUP_NAME
  exit 1
elif [ -z "$BACKUP_DATABASE" ]; then
  echo Error: Option must be set: BACKUP_DATABASE
  exit 1
elif [ -z "$BACKUP_FOLDER" ]; then
  echo Error: Option must be set: BACKUP_FOLDER
  exit 1
elif [ -z "$MYSQL_CONFIG" ]; then
  echo Error: Option must be set: MYSQL_CONFIG
  exit 1
elif [ -z "$ZIP_PASSWORD" ]; then
  echo Error: Option must be set: ZIP_PASSWORD
  exit 1
elif [ "$BACKUP_DATABASE" == "--all-databases" ] && [ ! -z "$TS_COLUMN" ]; then
  echo Error: TS_COLUMN must be left empty if BACKUP_DATABASE=--all-databases
  exit 1
elif [ ! -d "$BACKUP_FOLDER" ]; then
  echo Error: Backup Folder does not exists: $BACKUP_FOLDER
  exit 1
elif [ ! -d /tmp ]; then
  echo Error: /tmp directory missing
  exit 1
fi

# If TS_COLUMN is set, check if the last update to database is equal to the last backup
if [ ! -z "$TS_COLUMN" ]; then
  # Get the last of tables in database
  db_tables=$(mysql --defaults-extra-file="$MYSQL_CONFIG" $BACKUP_DATABASE -e "SHOW TABLES"|tail -n+2)

  if [ -z "$db_tables" ]; then
    echo Error: Unable to retrieve tables from database
    exit 1
  fi

  # Get the timestamp of the last update to database
  sql_query=""
  for db_table in $db_tables; do
    sql_query="$sql_query UNION SELECT $TS_COLUMN FROM $db_table"
  done
  sql_query="SELECT DATE_FORMAT(MAX($TS_COLUMN), '%Y-%m-%d.%H%i%s') FROM (${sql_query:7}) t"
  last_update=$(mysql --defaults-extra-file="$MYSQL_CONFIG" $BACKUP_DATABASE -e "$sql_query"|tail -n+2)

  if [ -z "$last_update" ]; then
    echo Error: Unable to retrieve last update timestamp from database
    exit 1
  fi

  # Get the timestamp of the latest copy of the backup
  last_backup=$(ls "$BACKUP_FOLDER"|grep "$BACKUP_NAME"|tail -n1|tr -s " "|rev|cut -d. -f3,4|rev)

  # If last update is equal to last backup, exit script
  if [ $last_update == "$last_backup" ]; then exit 1; fi
fi

if [ -z "$last_update" ]; then
  backup_name=$BACKUP_NAME.$(date +%Y-%m-%d.%H%M%S)
else
  backup_name=$BACKUP_NAME.$last_update
fi

cd /tmp

mysqldump --defaults-extra-file="$MYSQL_CONFIG" --hex-blob $BACKUP_DATABASE > "$backup_name.sql"
if [ $? -ne 0 ]; then
  echo Error: Unable to perform mysqldump
  exit 1
fi

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
