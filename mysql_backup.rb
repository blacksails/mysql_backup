$LOAD_PATH << '.'
require 'yaml'
require 'settings'
require 'optparse'
require 'mysql2'

class MySQLBackup
  include Settings

  def initialize
    check_if_root
    @options = {}
    handle_arguments
    @databases =[]
    load_config
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
                                password: Settings.mysql[:password])
    client.query('SELECT SCHEMA_NAME FROM `information_schema`.`SCHEMATA`;', symbolize_keys: true).each do |row|
      @databases << row[:schema_name]
    end
    puts @databases
  end
end

MySQLBackup.new