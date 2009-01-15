require 'rubygems'
gem 'sinatra', '~> 0.3'
require 'sinatra'
require 'json'

configure do
  require File.join(File.dirname(__FILE__), 'config', 'lost.rb')
end

before do
  Time.zone = IsLOSTOnYet.time_zone
end

get '/' do
  @is_lost_on = IsLOSTOnYet.answer
  haml :index
end

get '/tags' do
  # placeholders until implemented
  #
  # tags
  # @tags = %w(jack sayid kate s5e4)
  #
  # weighted tags
  @tags = [['jack', 54], ['kate', 45], ['s5e4', 30]]
  @tags.map { |(tag, weight)| tag } * ", " # temp output until theres a template
end

get '/episodeguide' do
  @episodes = IsLOSTOnYet.episodes
  @episodes.map { |e| e.to_s } * ", " # temp output until theres a template
end

get '/*' do
  @tags = params[:splat].first.split("/")
  # doesn't exist
  # @posts = IsLOSTOnYet::Post.by_tags(@tags)
  @tags * ", " # temp output until theres a template
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
  def users_for(posts)
    user_ids = posts.map { |p| p.user_id.to_i }
    user_ids.uniq!
    IsLOSTOnYet::User.where(:id => user_ids).inject({}) do |memo, user|
      memo.update user.id => user
    end
  end

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