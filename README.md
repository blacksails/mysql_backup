# MySQL Backup Script
This is an easy configurable backup script. It uses mysqldump to make the backup files, and rsync to transfer them to a
backup server.

## Installation
1. Clone the repo to the machine running MySQL.
2. Intall depdencies with `bundle install`
3. Run the script as root

        sudo -s
        ruby mysql_backup.rb

4. Optionally see available commands with `ruby mysql_backup.rb -h`

## Cron Job
The timing of the cron job can be changed from within the file `config/schedule.rb`. After modification be sure to run
`ruby mysql_backup.rb -c` which updates the information in the crontab.

## TODO
This section is for ideas to improve the script

- Make the script an executable with `#!`
- Use convention of naming rsync backup dir the hostname of the machine from which the backup comes from
- Make a flag for transfering untrasfered files, or make retries automatic
- Make a logfile for failures
- Change the way check_if_root works, so that the script can be run with sudo or simply su.
