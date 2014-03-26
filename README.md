# MySQL Backup Script
**The script is currently in development, and should NOT be used in production.** This is an easy configurable backup script. It uses mysqldump to make the backup files, and rsync to transfer them to a
backup server.

## Installation
1. Clone the repo to the machine running MySQL.
2. Run mysql_backup.rb and fill out the initial configuration
3. Create a cron job which runs the script at the interval in which you want backups