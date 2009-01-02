require 'rubygems'
require 'sinatra'

get '/' do
  erb :index
end

get '/json' do
  json = "no"
  if params[:callback]
    "#{params[:callback]}(#{json})"
  else
    json
  end
end