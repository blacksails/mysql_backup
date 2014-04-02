require 'psych'
require 'io/console'
require 'fileutils'

module Settings

  extend self

  @settings = {}

  def load!
    @settings = Psych.load_file(File.dirname(__FILE__)+'/config.yml')
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
    printf 'Enter rsync user: '
    rsync_user = gets.chomp
    printf 'Enter rsync path: '
    rsync_path = gets.chomp
    settings = {
        mysql: {
            user: mysql_user,
            pass: mysql_password,
        },
        rsync: {
            host: rsync_host,
            user: rsync_user,
            path: rsync_path
        }
    }

    f = File.new(File.dirname(__FILE__)+'/config.yml', 'w')
    f.chown(-1,0)
    f.chmod(0600)
    f.write Psych.dump(settings)
    f.close
    load!
  end

end