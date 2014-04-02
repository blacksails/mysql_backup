require 'optparse'

module Options
  extend self

  # Option defaults
  @options = {
      reset_config: false,
      use_remote: true
  }

  def handle_arguments!
    o = OptionParser.new do |opts|
      opts.banner = 'Usage: mysql_backup.rb [options]'
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
      opts.on('-r', '--reset-config', 'Reset the config file') {
          handle_r_flag
      }
      opts.on('-w', '--without-remote', 'Runs backup without moving it to a remote location') do |v|
        @options[:use_remote] = v
      end
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
    if answer and File.exist? File.dirname(__FILE__)+'/config.yml'
      FileUtils.rm File.dirname(__FILE__)+'/config.yml'
    else
      puts 'OK. Aborting...'
      exit
    end
  end

  def get_y_or_n(tries=0)
    ans = gets.chomp.downcase
    if ans =~ /^y(|es)$/
      true
    elsif ans =~ /^n(|o)$/
      false
    else
      tries += 1
      if tries == 5
        puts 'Too many failed attempts. Get a new job!'
        exit
      end
      printf "Please enter 'y' or 'n': "
      get_y_or_n(tries+1)
    end
  end

end