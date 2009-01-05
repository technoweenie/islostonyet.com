require 'yaml'
module IsLOSTOnYet
  class << self
    attr_accessor :episodes_by_season
    attr_accessor :episodes_by_code
    attr_accessor :episodes
  end

  def self.load_episodes(filename)
    self.episodes_by_code   = {}
    self.episodes_by_season = {}
    (self.episodes = Episode.load(filename)).each do |ep|
      season = ep.code.scan(/^s(\d+)/).first.first.to_i
      episodes_by_code[ep.code.to_sym] = ep
      (episodes_by_season[season] ||= []).unshift(ep)
    end
  end

  # code should =~ /^s\d+e\d+$/
  def self.episode(code)
    episodes_by_code[code]
  end

  # code should =~ /^s?\d+$/
  def self.season(code)
    season = code.to_s.sub(/^s/, '').to_i
    episodes_by_season[season]
  end

  def self.answer
    now             = Time.now.utc
    next_episode    = nil
    current_episode = episodes.detect do |episode|
      if episode.current?(now)
        true
      else
        next_episode = episode
        false
      end
    end
    {:answer => build_answer(current_episode, now), :reason => build_reason(current_episode, next_episode)}
  end

  class Episode < Struct.new(:code, :title, :air_date)
    class << self
      attr_accessor :episodes_path
    end
    self.episodes_path = File.join(File.dirname(__FILE__), '..', '..', 'episodes')

    def current?(now)
      now > air_date
    end

    def old?(now)
      now > (air_date + 1.month)
    end

    def self.load(filename)
      YAML.load_file(File.join(episodes_path, "#{filename}.yml")).map do |(code, data)|
        Episode.new(code, data['title'], data['air_date'])
      end.sort! { |x, y| y.air_date <=> x.air_date }
    end

    def to_s
      code
    end

    def inspect
      %(#<IsLOSTOnYet::Episode(#{code}) #{title.inspect}, air#{Time.now < air_date ? :ing : :ed} on #{air_date.in_time_zone.inspect}>)
    end
  end

private
  def self.build_answer(current_episode, now)
    (current_episode.nil? || current_episode.old?(now)) ? :no : :yes
  end

  def self.build_reason(current_episode, next_episode)
    episode = next_episode || current_episode
    season, ep = episode.code.scan(/^s(\d+)e(\d+)$/).first
    "Season #{season}#{", episode #{ep}" if current_episode && ep != '1'} start#{next_episode ? :s : :ed} on #{episode.air_date.in_time_zone.strftime("%b %d, %I %p %Z")}"
  end
end