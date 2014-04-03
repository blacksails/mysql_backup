require 'optparse'

module Options
  extend self

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
                  ' Feel free to change timing in config/schedule.rb, and then run this command.') {
        handle_c_flag
      }
      opts.on('-d', '--remove-cron-job', 'Removes the mysqlbackup cron job.') { handle_d_flag }
    end
    begin o.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts o
      exit
    end
  end

  def method_missing(name, *args, &block)
    @options[name.to_sym] ||
        fail(NoMethodError, "unknown option root #{name}", caller)
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
      exit
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