require 'optparse'
require 'time_diff'
require_relative 'settings'

module Options

  extend self

  # Default options
  @options = {
      without_remote: false
  }

  I18n.config.enforce_available_locales = false

  def handle_arguments!
    o = OptionParser.new do |opts|
      opts.banner = 'Usage: mysql_backup.rb [options]'
      opts.on_tail('-h', '--help', 'Show this message.') do
        puts opts
        exit
      end
      opts.on('-r', '--reset-config', 'Reset the config file.') { handle_r_flag }
      opts.on('-w', '--without-remote', 'Runs backup without moving it to a remote location.') do |v|
        @options[:without_remote] = v
      end
      opts.on('-c', '--update-cron',
              'Updates the cron job according to the file config/schedule.rb.'+
                  ' Feel free to change timing in config/schedule.rb, and then run this command.') { handle_c_flag }
      opts.on('-d', '--remove-cron-job', 'Removes the mysqlbackup cron job.') { handle_d_flag }
      opts.on('-b', '--time-since-last-backup',
              'Reports the time since the last backup. '+
                  'Exits with exit code 1 if the time is greater than 24h') { handle_b_flag }
      opts.on('-t', '--untransfered-backups',
              'Reports the number of untransfered backups (Backups which have not been moved to a remote server). '+
                  'Exits with exit code 1 if the number is greater than 0.') { handle_t_flag }
      opts.on('-T', '--transfer-untransfered-backups',
              'Transfer untransfered backups to backup server.') { handle_cap_t_flag }
    end
    begin o.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts o
      exit 1
    end
  end

  def method_missing(name, *args, &block)
    if @options.has_key? name.to_sym
      @options[name.to_sym]
    else
      fail(NoMethodError, "unknown option root #{name}", caller)
    end
  end

  private
  # Methods for flag handling
  def handle_r_flag
    printf 'Are you sure that you want to reset the config? [y/n]: '
    answer = get_y_or_n
    if answer
      if File.exist? File.dirname(__FILE__)+'/config/config.yml'
        FileUtils.rm File.dirname(__FILE__)+'/config/config.yml'
      end
      puts 'Config has been reset!'
      exit
    else
      puts 'OK. Aborting...'
      exit 1
    end
  end

  def handle_c_flag
    puts 'Updating cron job according to schedule.rb...'
    system 'whenever -i mysqlbackup'
    puts "Done."
    exit
  end

  def handle_d_flag
    puts 'Removing cron job(s).'
    system 'whenever -c mysqlbackup'
    puts 'Done'
    exit
  end

  def handle_b_flag
    Settings.load!
    now = Time.now
    timediff = Time.diff now, Settings.backup[:last_backup], '%h:%m:%s'
    puts "Time since last backup: #{timediff[:diff]}"
    timediff = Time.diff now, Settings.backup[:last_backup], '%h'
    if timediff[:diff].to_i > 24
      exit 1
    end
    exit
  end

  def handle_t_flag
    path = File.dirname(__FILE__)+'/localbackup'
    number_of_dirs = Dir.entries(path).count do |entry|
      File.directory? File.join(path, entry) and !(entry =='.' || entry == '..')
    end
    puts "Number of untransfered files: #{number_of_dirs}"
    if number_of_dirs > 0
      exit 1
    end
    exit
  end

  def handle_cap_t_flag
    puts 'Transfering untransered backups...'
    Settings.load!
    path = File.dirname(__FILE__)+'/localbackup'
    dirs = Dir.entries(path).select do |entry|
      File.directory? File.join(path, entry) and !(entry =='.' || entry == '..')
    end
    dirs.each do |dir|
      fullpath = path + '/' + dir
      success = system  "rsync -a #{fullpath} #{Settings.rsync[:user]}@#{Settings.rsync[:host]}"+
                            ":#{Settings.rsync[:path]}"
      if success
        puts 'Succesfully transfered '+fullpath
        FileUtils.rm_r fullpath
      else
        puts "There was a problem moving the following databasedump to the backup server. #{fullpath}"
        puts 'Aborting...'
        exit 1
      end
    end
    puts 'Done!'
    exit
  end

  # Private helper methods
  def get_y_or_n
    ans = gets.chomp.downcase
    if ans =~ /^y(|es)$/
      true
    elsif ans =~ /^n(|o)$/
      false
    else
      printf "Please enter 'y' or 'n': "
      get_y_or_n
    end
  end

end