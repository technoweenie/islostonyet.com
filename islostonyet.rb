$LOAD_PATH << File.join(File.dirname(__FILE__), 'vendor', 'atom_feed_helper', 'lib')
require 'rubygems'
gem 'builder', '~> 2.1'
gem 'sinatra', '~> 0.3'
require 'haml'
require 'sinatra'
require 'json'
require 'atom_feed_helper'

class Rack::Request
  alias request_uri fullpath
end

configure do
  require File.join(File.dirname(__FILE__), 'config', 'lost.rb')
end

before do
  Time.zone   = IsLOSTOnYet.time_zone
  @is_lost_on = IsLOSTOnYet.answer
end

get '/stylesheets/:name.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :"stylesheets/#{params[:name]}", :sass => {:style => :compact, :load_paths => [File.join(Sinatra::Application.views, 'stylesheets')]}
end

get '/' do
  @posts   = []
  @users   = []
  @body_class = "latest"
  haml :index
end

get '/widget' do
  @posts   = []
  @users   = []
  @body_class = "widget"
  haml :widget
end

get '/widget.js' do
  content_type 'text/javascript', :charset => 'utf-8'
  haml :widget_js, :layout => false
end

get '/widget.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :"stylesheets/#{IsLOSTOnYet.show_abbrev.downcase}_widget", :style => :compact, :load_paths => [File.join(Sinatra.application.options.views, 'stylesheets')]
end

get '/updates.atom' do
  @posts = []
  @users = []
  builder :updates
end

get '/episodes' do
  @episodes   = IsLOSTOnYet.episodes
  @body_class = "episodes"
  haml :episodes
end

get '/json' do
  json = IsLOSTOnYet.answer.to_json
  if params[:callback]
    "#{params[:callback]}(#{json})"
  else
    json
  end
end

helpers do
  include AtomFeedHelper

  def mobile_safari?
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/]
  end
  
  def partial(page, options={})
    haml page, options.merge!(:layout => false)
  end

  def page_number
    @page_number ||= begin 
      num = params[:page].to_i
      num.zero? ? 1 : num
    end
  end

  def time_ago_or_time_stamp(from_time, to_time = Time.zone.now, include_seconds = true, detail = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round
    case distance_in_minutes
      when 0..1 then time = (distance_in_seconds < 60) ? "#{distance_in_seconds} seconds ago" : 'a minute ago'
      when 2..59 then time = "#{distance_in_minutes} minutes ago"
      when 60..90 then time = "an hour ago"
      when 90..1440 then time = "#{(distance_in_minutes.to_f / 60.0).round} hours ago"
      when 1440..2160 then time = 'a day ago' # 1-1.5 days
      when 2160..2880 then time = "#{(distance_in_minutes.to_f / 1440.0).round} days ago" # 1.5-2 days
      else time = from_time.strftime("%d %B %Y")
    end
    return time_stamp(from_time) if (detail && distance_in_minutes > 2880)
    return time
  end

  def users_for(posts)
    user_ids = posts.map { |p| p.user_id.to_i }
    user_ids.uniq!
    IsLOSTOnYet::User.where(:id => user_ids).inject({}) do |memo, user|
      memo.update user.id => user
    end
  end

  def page_title(answer = nil)
    if answer
      "Is #{IsLOSTOnYet.show_abbrev}#{" (Season #{answer.next_episode.season})" if answer.next_episode} on yet?"
    elsif params[:episode]
      "Is #{IsLOSTOnYet.show_abbrev} (Season #{params[:season]}, Episode #{params[:episode]}) on yet?"
    elsif params[:season]
      "Is #{IsLOSTOnYet.show_abbrev} (Season #{params[:season]}) on yet?"
    else
      "Is #{IsLOSTOnYet.show_abbrev} on yet?"
    end
  end
end