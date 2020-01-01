# sh backuper

## Description

Old backup script that I used for backups. The script is a wrapper around `rsync` with additional functions, such as incremental backups, sym links, free space check, backup verification, file logs, telegram notifications, etc.

# Before first use

All personal information has been replaced with dummy data and commented with `TODO`. Please replace them before use.

Backup items are configured using `backuper/list.csv` file. The file has backup name and path to what has to be be backed up, separated by comma.

# Usage

Simply run `sudo backuper/backuper.sh`

# Additional information

The script should be run by privileged user, because it uses some privileged user features, such as logging to `/var/log` or creating lock file in `/var/lock`.

Only rsync key-pair auth is supported for backing up to remote server.

By default only last 30 backups are kept. This number can be changed using `BACKUPS_LIMIT` variable in `backuper/make_backup.sh`