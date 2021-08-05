# Mini Bash Scripts
Simple scripts to help with your linux administration.

## ping.sh
Try to ping a port number of a hostname. If ping fails, a notification with sent from a Telegram bot. This is meant to be used with the crontab.

`NOTIFICATION_COOLDOWN` refers to the number of seconds to wait before the next notification can be sent. This is to prevent your chat from being flooded. You can set this to empty if you prefer to receive a notification every time this script is executed.

Whenever you can finally ping again, a "success" notification will be sent regardless of the current `NOTIFICATION_COOLDOWN` status.

Download: `wget https://raw.githubusercontent.com/yyscolin/MiniBash/master/ping.sh`

## rsynker.sh
This script is equivalent to using the rsync command with the `-a` and `--delete` options, except that:
- The script won't run if an instance is already running. So it's more suitable for cronjobs where the interval is expected to be possibly shorter than the time taken to complete the script.
- The script will only run if there are differences. This is to prevent the `--log-file` file from being flooded with empty transfers.

Options:
- You can add as many `EXCLUDE` into the script to `--exclude` their patterns.
- You may use the `-n` or `--dry-run` option.

Download: `wget https://raw.githubusercontent.com/yyscolin/MiniBash/master/rsynker.sh`
