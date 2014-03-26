$LOAD_PATH << '.'
require 'yaml'
require 'settings'
require 'optparse'
require 'mysql2'
require 'fileutils'

class MySQLBackup
  include Settings
  include FileUtils

  def initialize
    check_if_root
    @options = {}
    handle_arguments
    load_config
    @databases =[]
    get_database_names
    dump_databases
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
    if @options[:reset_config]
      if File.exist? 'config.yml'
        File.delete 'config.yml'
      end
    end

    if File.exist? 'config.yml'
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
  end

  def dump_databases
    dirname = Time.now.strftime("%Y%m%d")
    if Dir.exist? dirname
      FileUtils.rm_r dirname
    end
    FileUtils.mkdir dirname
    @databases.each do |db|
      system "mysqldump -u#{Settings.mysql[:user]} -p#{Settings.mysql[:pass]} #{db} | gzip > #{dirname}/#{db}.sql.gz"
    end
  end
end

MySQLBackup.new