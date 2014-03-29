#$LOAD_PATH << '.'
require_relative 'settings'
require_relative 'options'
require 'mysql2'
require 'fileutils'

class MySQLBackup

  def initialize
    @root_path = File.dirname(__FILE__)+'/'
    check_if_root
    Options.handle_arguments!
    load_config
    @databases = []
    get_database_names
    @dirname = 'default'
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
    # deletes the config on the -r flag
    if Options.reset_config
      if File.exist? @root_path+'config.yml'
        FileUtils.rm @root_path+'config.yml'
      end
    end
    # creates new config if none is found
    unless File.exist? @root_path+'config.yml'
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
  end

  def dump_databases
    @dirname = Time.now.strftime("mysql-%Y%m%d-%H%M")
    if Dir.exist? @root_path+@dirname
      FileUtils.rm_r @root_path+@dirname
    end
    FileUtils.mkdir @root_path+@dirname
    @databases.each do |db|
      system "mysqldump -u#{Settings.mysql[:user]} -p#{Settings.mysql[:pass]} #{db} | "+
                 "gzip > #{@root_path+@dirname}/#{db}.sql.gz"
    end
  end

  def move_dumps_to_backup_server
    unless Options.use_remote
      system  "rsync -a #{@root_path+@dirname} #{Settings.rsync[:user]}@#{Settings.rsync[:host]}:#{Settings.rsync[:path]}"
    end
  end

end

MySQLBackup.new