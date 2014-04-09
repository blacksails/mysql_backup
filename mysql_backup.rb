#!/usr/bin/env ruby
require_relative 'settings'
require_relative 'options'
require 'mysql2'
require 'fileutils'

class MySQLBackup

  def initialize
    check_if_root
    @root_path = File.dirname(__FILE__)+'/'
    Dir.chdir @root_path
    @databases = []
    @dirname = Time.now.strftime("mysql-%Y%m%d-%H%M")
    Options.handle_arguments!
    load_config
    get_database_names
    dump_databases
    move_dumps_to_backup_server
  end

  def check_if_root
    if ENV['USER'] != 'root'
      puts 'You need root privileges to run this script'
      exit 1
    end
  end

  def load_config
    # creates new config if none is found
    if File.exist? @root_path+'/config/config.yml'
      Settings.load!
    else
      Settings.create!
    end
  end

  def get_database_names
    client = Mysql2::Client.new(host: 'localhost',
                                username: Settings.mysql[:user],
                                password: Settings.mysql[:pass])
    client.query('SELECT SCHEMA_NAME '+
                     'FROM `information_schema`.`SCHEMATA`'+
                     'WHERE SCHEMA_NAME<>"information_schema"'+
                     'AND SCHEMA_NAME<>"performance_schema";',
                 symbolize_keys: true
    ).each do |row|
      @databases << row[:SCHEMA_NAME]
    end
    client.close
  end

  def dump_databases
    puts 'Dumping databases...'
    if Dir.exist? @root_path+@dirname
      FileUtils.rm_r @root_path+@dirname
    end
    FileUtils.mkdir @root_path+@dirname
    @databases.each do |db|
      success = system "mysqldump -u#{Settings.mysql[:user]} -p#{Settings.mysql[:pass]} #{db} | "+
                 "gzip > #{@root_path+@dirname}/#{db}.sql.gz"
      unless success
        puts "A problem was encountered when dumping the database #{db}"
        FileUtils.rm_r @root_path+@dirname
        exit 1
      end
    end
    Settings.set_backup_time!
    puts 'Done!'
  end

  def move_dumps_to_backup_server
    unless Options.without_remote # checks if the -w flag has been set
      puts 'Moving files to backup server...'
      success = system  "rsync -a #{@root_path+@dirname} #{Settings.rsync[:user]}@#{Settings.rsync[:host]}"+
                  ":#{Settings.rsync[:path]}"
      if success
        FileUtils.rm_r @root_path+@dirname
        puts 'Done!'
      else
        FileUtils.mv @root_path+@dirname, @root_path+'/localbackup/'
        puts 'There was a problem moving the database dumps to the backup server. Dumps have been kept here!'
        exit 1
      end
    end
  end

end

MySQLBackup.new