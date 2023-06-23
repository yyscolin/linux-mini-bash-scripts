#!/bin/bash
BACKUP_NAME=mysqldump
BACKUP_DATABASE=--all-databases
BACKUP_FOLDER=/example/location/folder
MYSQL_CONFIG=~/.my.cnf
TS_COLUMN=update_timestamp
ZIP_PASSWORD=password

### Notes ###

# BACKUP_NAME
# The name of the backup file to be used, will be appended with current timestamp

# TS_COLUMN: Optional
# The database column name which represents the timestamp of the row last updated
# If added, BACKUP_NAME will be appended with the last updated timestamp instead
# Backup will be skipped if last backup is later than last update
# Must be left empty if BACKUP_DATABASE=--all-databases
# `update_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

# ZIP_PASSWORD must not be left blank due to security

# .my.cnf sample:
# [mysqldump]
# user=admin
# password=password
#
# [mysql]
# user=admin
# password=password
