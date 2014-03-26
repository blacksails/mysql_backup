require 'psych'
require 'io/console'

module Settings

  extend self
  attr_reader :settings

  @settings = {}

  def load!
    @settings = Psych.load_file('config.yml')
  end

  def method_missing(name, *args, &block)
    @settings[name.to_sym] ||
        fail(NoMethodError, "unknown configuration root #{name}", caller)
  end

  def create!
    puts 'It appears that we lack a configuration file, lets create one now!'
    printf 'Enter MySQL user name: '
    mysql_user = gets.chomp
    printf 'Enter MySQL password: '
    mysql_password = STDIN.noecho(&:gets).chomp; puts
    printf 'Enter rsync host: '
    rsync_host = gets.chomp
    printf 'Enter rsync path: '
    rsync_path = gets.chomp
    settings = {
        mysql: {
            user: mysql_user,
            pass: mysql_password,
        },
        rsync: {
            host: rsync_host,
            path: rsync_path
        }
    }

    f = File.new 'config.yml', 'w'
    f.chown(-1,0)
    f.chmod(0600)
    f.write Psych.dump(settings)
    load!
  end

end