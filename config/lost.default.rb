# Sequel::Model.db = Sequel.connect('mysql://localhost/lost')
Sequel::Model.db = Sequel.sqlite
# in memory DB by default, so loading schema
IsLOSTOnYet.setup_schema

IsLOSTOnYet.twitter_login    = ''
IsLOSTOnYet.twitter_password = ''