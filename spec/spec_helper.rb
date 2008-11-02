require 'rubygems'
require 'activerecord'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

ActiveRecord::Base.establish_connection(config['sqlite3'])

load(File.dirname(__FILE__) + "/schema.rb")
require File.dirname(__FILE__) + '/../init.rb'