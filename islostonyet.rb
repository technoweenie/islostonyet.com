require 'rubygems'
gem 'sinatra', '~> 0.3'
require 'sinatra'
require 'json'

get '/' do
  erb :index
end

get '/json' do
  json = is_lost_on_yet?.to_json
  if params[:callback]
    "#{params[:callback]}(#{json})"
  else
    json
  end
end

helpers do
  def is_lost_on_yet?
    @is_lost_on_yet ||= {:answer => "no", :reason => "returns on Jan 21st, 9PM ET"}
  end
end