require 'psych'
require 'io/console'
require 'fileutils'

module Settings

  extend self

  @settings = {}

  def load!
    @settings = Psych.load_file(File.dirname(__FILE__)+'/config/config.yml')
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
    printf "Do you want to set a cron job if there isen't one already? [y/n]: "
    cron_job = get_y_or_n
    if cron_job
      system 'whenever -i mysqlbackup'
    end
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

    f = File.new(File.dirname(__FILE__)+'/config/config.yml', 'w')
    f.chown(-1,0)
    f.chmod(0600)
    f.write Psych.dump(settings)
    f.close
    load!
  end

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