$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$testing = true
require 'is_lost_on_yet'

Sequel::Model.db = Sequel.sqlite
IsLOSTOnYet.setup_schema
IsLOSTOnYet.init
IsLOSTOnYet::Episode.episodes_path = File.join(File.dirname(__FILE__), 'episodes')

gem 'rr', '~> 0.6'
gem 'jeremymcanally-context' # sudo gem install jeremymcanally-context --source=http://gems.github.com
gem 'jeremymcanally-matchy'  # sudo gem install jeremymcanally-matchy  --source=http://gems.github.com

require 'rr'
require 'context'
require 'matchy'
require 'logger'

# Sequel::Model.db.logger = Logger.new(STDOUT)
IsLOSTOnYet.twitter_login = 'lostie'
Time.zone = "Eastern Time (US & Canada)"

class Faux
  class User < Struct.new(:id, :name, :profile_image_url)
  end

  class Post < Struct.new(:id, :text, :user, :created_at)
  end
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  def self.transaction(&block)
    Sequel::Model.db.transaction &block
  end

  def transaction(&block)
    self.class.transaction(&block)
  end

  def cleanup(*models)
    transaction { models.each { |m| m.delete_all } }
  end
end

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end