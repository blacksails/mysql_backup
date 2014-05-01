# MySQL Backup Script
This is an easy configurable backup script. It uses mysqldump to make the backup files, and rsync to transfer them to a
backup server.

## Dependencies
1. The script has been written based on Ruby v2.1.1, but it should work on anything greater or equal than 2.0.0.
2. The mysql2 gem relies on the MySQL library.

        yum install mysql-devel

3. The fileutils gem relies on the imagemagick library

        yum install ImageMagick-devel

## Installation
1. Clone the repo to the machine running MySQL.
2. Intall depdencies with `bundle install`
3. Run the script as root

        sudo mysql_backup.rb

4. Optionally see available commands with `sudo mysql_backup.rb -h`

## Cron Job
The timing of the cron job can be changed from within the file `config/schedule.rb`. After modification be sure to run
`./mysql_backup.rb -c` which updates the information in the crontab.

## TODO
This section is for ideas to improve the script

- ~~Make the script an executable with `#!`~~ **Done!**
- Use convention of naming rsync backup dir the hostname of the machine from which the backup comes from
- ~~Make a flag for transfering untrasfered files~~, or make retries automatic
- Make a logfile for failures
- ~~Change the way check_if_root works, so that the script can be run with sudo or simply su.~~
- ~~Make flags for backuperrors that can be used by SNMP~~ **Done!**
- Make the script work on Mac OS
