# Mini Bash Scripts
Simple scripts to help with your linux administration.
- Clone this repository
- Make a copy of the respective sample settings files from `profiles.sample` into the `profiles` folder. For example, if you want to use the ping.sh script: `cp ./MiniBash/profiles.sample/ping.sh ./MiniBash/profiles/ping.exmaple.sh`
- Edit the settings file accordingly
- Run the script like this: `./MiniBash/ping.sh ./MiniBash/profiles/ping.exmaple.sh`
- Optional: Add into your crontab

## mysqldump.sh
Creates backup for mysql databases compressed into .tar.7z and then sent to a folder.

## ping.sh
Try to ping a hostname, with an optional port number. If ping fails, a notification will be sent from a Telegram bot. This is meant to be used with the crontab.

`NOTIFICATION_COOLDOWN` refers to the number of seconds to wait before the next notification can be sent. This is to prevent your chat from being flooded. You can set this to empty if you prefer to receive a notification every time this script is executed and the ping fails.

Whenever you can finally ping again, a "success" notification will be sent regardless of the current `NOTIFICATION_COOLDOWN` status.

## rsynker.sh
This script is equivalent to using the rsync command with the `-a` and `--delete` options, except that:
- The script won't run if an instance is already running. So it's more suitable for cronjobs where the interval is expected to be possibly shorter than the time taken to complete the script.
- The script will only run if there are differences. This is to prevent the `--log-file` file from being flooded with empty transfers.

Options:
- You can add as many `EXCLUDE` into the script to `--exclude` their patterns.
- You may set the `IS_DRYRUN` option to `true`. This is the same as using the `-n` or `--dry-run` option for the rsync command.

## check_ip.sh
A simple cronjob script to check if your dynamic public IP address has been changed. If a change was detected, a notification will be sent from a Telegram bot.

## disk_health.sh
A simple cronjob script to check the SMART overall-health self-assessment test result of your disks, which is the equivalent of `smartctl -H /dev/sdX`. If the result is anything other than `PASSED`, a notification will be sent from a Telegram bot.
