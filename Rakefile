require 'rubygems'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

desc "Default task is to run specs"
task :default => :test

namespace :lost do
  task :init do
    require File.join(File.dirname(__FILE__), 'config', 'lost.rb')
  end

  desc "Reset DB schema"
  task :schema => :init do
    IsLOSTOnYet.setup_schema
    twit = IsLOSTOnYet.twitter.user(IsLOSTOnYet.twitter_login)
    IsLOSTOnYet::User.create(:login => twit.screen_name, :external_id => twit.id, :avatar_url => twit.profile_image_url)
  end

  desc "Process all updates from the existing Twitter user"
  task :process_updates => :init do
    IsLOSTOnYet::Post.process_updates
  end

  desc "Process all search results from Twitter"
  task :process_search => :init do
    IsLOSTOnYet::Post.process_search
  end

  desc "Process all replies to the existing Twitter user"
  task :process_replies => :init do
    IsLOSTOnYet::Post.process_replies
  end

  task :cleanup => :init do
    IsLOSTOnYet::Post.cleanup
  end
end