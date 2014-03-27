$LOAD_PATH << '.'
require 'yaml'
require_relative 'settings'
require 'optparse'
require 'mysql2'
require 'fileutils'

class MySQLBackup
  include Settings
  include FileUtils

  def initialize
    @root_path = File.dirname(__FILE__)+'/'
    check_if_root
    handle_arguments
    load_config
    @databases =[]
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

  def handle_arguments
    o = OptionParser.new do |opts|
      opts.banner = 'Usage: mysql_backup.rb [options]'
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
      opts.on('-r', '--reset-config', 'Reset the config file') {|v| @options[:reset_config] = true}
    end
    begin o.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts o
      exit 1
    end
  end

  def load_config
    # reset the config on the -r flag
    if @options[:reset_config]
      if @root_path+'config.yml'
        FileUtils.rm @root_path+'config.yml'
      end
    end
    unless File.exist? @root_path+'config.yml'
      Settings.create!
    end
    Settings.load!
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
    @dirname = Time.now.strftime("%Y%m%d")
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
    system  "rsync -a #{@root_path+@dirname} #{Settings.rsync[:user]}@#{Settings.rsync[:host]}:#{Settings.rsync[:path]}"
  end
end

MySQLBackup.new