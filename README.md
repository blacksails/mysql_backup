# MySQL Backup Script
**The script is currently in development, and should NOT be used in production.** This is an easy configurable backup
script. It uses mysqldump to make the backup files, and rsync to transfer them to a backup server.

## Installation
1. Clone the repo to the machine running MySQL.
2. Intall depdencies with `bundle install`
2. Run the script as root
~~~~
sudo -s
ruby mysql_backup.rb
~~~~

## TODO
This section is for ideas to improve the script
- Make the script an executable with `#!`
- Use convention of naming rsync backup dir the hostname of the machine from which the backup comes from
- Make a flag for transfering untrasfered files, or make retries automatic
- Make a logfile for failures
