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

  # see http://search.twitter.com/advanced
  # Probably only want :containing, but go nuts if you like
  IsLOSTOnYet.twitter_search_options = {
    :from => 'technoweenie',
    :to   => 'technoweenie',
    :referencing => 'technoweenie',
    :containing  => "lost OR kate OR sayid",
    :hashed      => "lost",
    :lang        => "en",
    :per_page    => 50,
    :since       => '13423423', # unneeded, this wonderful site will fill this in for you!
    :geocode     => [long, lat, range]
  }
end

IsLOSTOnYet.load_episodes :lost