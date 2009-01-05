require 'rubygems'
require 'rake/testtask'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

desc "Default task is to run specs"
task :default => :test

namespace :lost do
  task :init do
    require 'is_lost_on_yet'
  end

  desc "Reset DB schema"
  task :schema => :init do
    IsLOSTOnYet.setup_schema
  end

  desc "Process all updates from the existing Twitter user"
  task :process_updates => :init do
    IsLOSTOnYet::Post.process_updates
  end

  desc "Process all replies to the existing Twitter user"
  task :process_replies do
    IsLOSTOnYet::Post.process_replies
  end
end