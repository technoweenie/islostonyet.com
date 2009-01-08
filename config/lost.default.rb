$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'is_lost_on_yet'

IsLOSTOnYet.init do
  # Sequel::Model.db = Sequel.connect('mysql://localhost/lost')
  Sequel::Model.db = Sequel.sqlite
  # in memory DB by default, so loading schema
  IsLOSTOnYet.setup_schema

  IsLOSTOnYet.time_zone        = "Eastern Time (US & Canada)"
  IsLOSTOnYet.twitter_login    = ''
  IsLOSTOnYet.twitter_password = ''
end

IsLOSTOnYet.load_episodes :lost