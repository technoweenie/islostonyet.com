require File.dirname(__FILE__) + "/../islostonyet.rb"

set :run, false
set :env, ENV['APP_ENV'] || :production

run Sinatra.application
