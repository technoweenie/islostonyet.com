module IsLOSTOnYet
  def self.answer(now = nil)
    now ||= Time.now.utc
    current_episode, next_episode = current_and_next_episodes(now)
    Answer.new(now, current_episode, next_episode, build_answer(current_episode, now), build_reason(current_episode, next_episode))
  end

  def self.current_and_next_episodes(now = nil)
    return [nil, nil] if episodes.nil? || episodes.empty?

    now           ||= Time.now.utc
    next_episode    = nil
    current_episode = episodes.detect do |episode|
      if episode.current?(now)
        true
      else
        next_episode = episode
        false
      end
    end
    [current_episode, next_episode]
  end

  class Answer < Struct.new(:now, :current_episode, :next_episode, :answer, :reason)
    def result
      @result ||= {:answer => answer, :reason => reason}
    end

    def to_json
      result.to_json
    end

    def spoiler?(episode)
      next_episode && (next_episode.air_date + 1.day < episode.air_date)
    end

    def inspect
      %(#<IsLOSTOnYet::Answer (as of #{now}) #{answer.to_s.upcase}; current: #{current_episode || '--'}, next: #{next_episode || '--'}>)
    end
  end
end