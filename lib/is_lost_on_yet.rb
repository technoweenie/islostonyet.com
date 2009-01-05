require 'rubygems'
gem 'activesupport', '~> 2.2'
gem 'sequel',        '~> 2.7'
gem 'twitter',       '~> 0.4'

require 'sequel'
require 'twitter'

# Mmm, timezones
require 'active_support/basic_object'
require 'active_support/time_with_zone'
require 'active_support/values/time_zone'
require 'active_support/core_ext/object'
require 'active_support/core_ext/date'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/time'
require 'active_support/duration'

module IsLOSTOnYet
  class << self
    attr_accessor :twitter_login
    attr_accessor :twitter_password

    def twitter
      @twitter ||= Twitter::Base.new(twitter_login, twitter_password)
    end

    def init
      %w(episode user post).each { |l| require "is_lost_on_yet/#{l}" }
    end
  end
end

require 'is_lost_on_yet/schema'

# this is horrible, i need a better way to lay this out
unless $testing
  config_path = File.join(File.dirname(__FILE__), '..', 'config', 'lost.rb')
  if File.exist?(config_path)
    require config_path
    IsLOSTOnYet.init
  end
end