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
  # Probably only want :main_keywords and :secondary_keywords, but go nuts if you like
  #
  # :main_keywords and :secondary_keywords are used for basic scoring of search results to determine
  # if they are really about the tv show.  :main_keywords build the the :containing query part of the search.  
  # When parsing search results, a score is kept for the occurence of main and secondary words.  Ideally we want
  # AT LEAST 1 main word, and a total of 1 main + 1 secondary (2 points).  A hashtag counts as 2 points though.
  IsLOSTOnYet.twitter_search_options = {
    :main_keywords => %w(lost #lost kate sayid), # these are joined with an OR to make the same :containing query below
    :secondary_keywords => %w(tv season)
    :from => 'technoweenie',
    :to   => 'technoweenie',
    :referencing => 'technoweenie',
    :containing  => "lost OR kate OR sayid",
    :hashed      => "lost",
    :lang        => "en",
    :per_page    => 50,
    :since       => '13423423', # unneeded, this wonderful site will fill this in for you!
    :geocode     => [@long, @lat, @range]
  }
end

IsLOSTOnYet.load_episodes :lost