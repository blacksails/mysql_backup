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
          |v| @options[:reset_config] = true
      }
      opts.on('-w', '--without-remote', 'Runs backup without moving it to a remote location') {
          |v| @options[:use_remote] = true
      }
    end
    begin o.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts o
      exit 1
    end
  end

  def method_missing(name, *args, &block)
    @options[name.to_sym] ||
        fail(NoMethodError, "unknown option root #{name}", caller)
  end

end