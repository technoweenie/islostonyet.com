require 'rubygems'
gem 'sinatra', '~> 0.3'
require 'sinatra'
require 'json'

configure do
  require File.join(File.dirname(__FILE__), 'config', 'lost.rb')
end

get '/' do
  Time.zone   = IsLOSTOnYet.time_zone
  @is_lost_on = IsLOSTOnYet.answer
  haml :index
end

get '/s:season' do
  Time.zone = IsLOSTOnYet.time_zone
  @episodes = IsLOSTOnYet.season params[:season]
  haml :season
end

get '/s:season/e:episode' do
  Time.zone = IsLOSTOnYet.time_zone
  @episode = IsLOSTOnYet.episode :"s#{params[:season]}e#{params[:episode]}"
  haml :episode
end

get '/json' do
  json = IsLOSTOnYet.answer.to_json
  if params[:callback]
    "#{params[:callback]}(#{json})"
  else
    json
  end
end

get '/main.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :main
end

helpers do
  def page_title(answer = nil)
    if answer
      "Is LOST#{" (Season #{answer.next_episode.season})" if answer.next_episode} on yet?"
    elsif params[:episode]
      "Is LOST (Season #{params[:season]}, Episode #{params[:episode]}) on yet?"
    elsif params[:season]
      "Is LOST (Season #{params[:season]}) on yet?"
    else
      "Is LOST on yet?"
    end
  end
end