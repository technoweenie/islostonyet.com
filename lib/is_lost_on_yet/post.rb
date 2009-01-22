# used to transform twitter search results into duck typable twitter objects
class Faux
  class User < Struct.new(:id, :screen_name, :profile_image_url)
  end

  class Post < Struct.new(:id, :text, :user, :created_at)
    def to_search_result
      {'id' => id, 'text' => text, 'from_user' => user.screen_name, 'from_user_id' => user.id, 'created_at' => created_at, 'profile_image_url' => user.profile_image_url}
    end
  end
end

module IsLOSTOnYet
  class Post < Sequel.Model(:posts)
    many_to_one :user, :class => "IsLOSTOnYet::User"

    def self.list(page = 1)
      filter_and_order(:visible => true).paginate(page, 30).to_a
    end

    def self.find_by_tags(tags, page = 1)
      return [] if tags.empty?
      filter_and_order(:visible => true).
        where([Array.new(tags.size, "tag LIKE ?") * " AND ", *tags.map { |t| "%[#{t}]%" }]).
        paginate(page, 30).to_a
    end

    def self.process_search
      search = Twitter::Search.new
      if post = latest_search
        search.since(post.external_id)
      end
      if keywords = IsLOSTOnYet.twitter_search_options[:main_keywords]
        search.contains keywords.join(" OR ")
      end
      IsLOSTOnYet.twitter_search_options.each do |key, args|
        next if key == :main_keywords || key == :secondary_keywords
        args = [args]; args.flatten!
        search.send(key, *args)
      end
      process_search_results(search) do |user, post|
        !post.reply_to_bot? && user.external_id != IsLOSTOnYet.twitter_user.external_id && post.valid_search_result?
      end
    end

    def self.process_updates
      args  = [:user]
      if post = latest_update
        args << {:since_id => post.external_id}
      end
      process_tweets(IsLOSTOnYet.twitter.timeline(*args)) { |user, post| !post.reply? }
      IsLOSTOnYet.twitter_user.reload
    end

    def self.process_replies
      now    = Time.now.utc
      args   = []
      answer = IsLOSTOnYet.answer(now)
      if post = latest_reply
        args << {:since_id => post.external_id}
      end
      process_tweets(IsLOSTOnYet.twitter.replies(*args)) do |user, post|
        if post.inquiry?
          IsLOSTOnYet.twitter.update("@#{user.login} #{answer.reason}")
          false
        else
          post
        end
      end
    end

    def self.latest_update
      filtered_for_updates.select(:external_id).first
    end

    def self.latest_reply
      filtered_for_replies.where("body LIKE ?", "@#{IsLOSTOnYet.twitter_login}%").select(:external_id).first
    end

    def self.latest_search
      filtered_for_replies.where("body NOT LIKE ?", "@#{IsLOSTOnYet.twitter_login}%").select(:external_id).first
    end

    def formatted_body
      formatted = body.dup
      formatted.gsub! /^@#{IsLOSTOnYet.twitter_login}[ ,.;\-><:!?]+/im, ''                                # clear @reply
      formatted.gsub! /(\w+:\/\/[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_:%&\?\/.=]+)/im, '<a href="\1">\1</a>'      # link urls
      formatted.gsub! /@([a-zA-Z0-9\-_]+)([ ,.;\-><:!?]+|$)/im, '<a href="http://twitter.com/\1">@\1</a>\2' # link twitter users
      formatted.gsub! /([^&])#([a-zA-Z0-9\-_]+)/im, '\1<a href="/\2">#\2</a>'                             # link tags
      formatted
    end

    # a @reply tweet
    def reply?
      body.strip =~ /^@/
    end

    def reply_to_bot?
      body.strip =~ /^@#{IsLOSTOnYet.twitter_login}/i
    end

    # A tweet from a user asking the twitter bot if the show is on
    def inquiry?
      body.strip =~ /^@#{IsLOSTOnYet.twitter_login}\s*\?$/i
    end

    def visible?
      visible == true || visible == 1
    end

    def hash_tags
      @hash_tags ||= begin
        tags = body.scan(/(^|[^&])#([\w\d]+)/i).map { |s| s.last }
        tags.flatten!
        tags.each { |tag| tag.downcase! }
      end
    end

    def save_hash_tags
      existing = Tag.where(:name => hash_tags).to_a
      creating = hash_tags - existing.map { |t| t.name }
      creating.each do |name|
        existing << Tag.create(:name => name)
      end
      existing.each do |tag|
        Tagging << {:tag_id => tag.id, :post_id => id}
      end
      self.tag = existing.map { |tag| "[#{tag.name}]" }.sort! * " "
      save
    end

    def valid_search_result?
      if IsLOSTOnYet.twitter_search_options[:main_keywords].nil? then return true ; end
      score          = 0
      downcased_body = body.downcase
      score += score_from downcased_body, IsLOSTOnYet.twitter_search_options[:main_keywords]
      if score.zero? then return false ; end
      score += score_from downcased_body, IsLOSTOnYet.twitter_search_options[:secondary_keywords]
      score > 1
    end

  protected
    def self.filtered_for_updates
      user_id = IsLOSTOnYet.twitter_user ? IsLOSTOnYet.twitter_user.id : 0
      filter_and_order(:user_id => user_id)
    end

    def self.filtered_for_replies
      user_id = IsLOSTOnYet.twitter_user ? IsLOSTOnYet.twitter_user.id : 0
      filter_and_order(['user_id != ?', user_id])
    end

    def self.filter_and_order(*args)
      where(*args).order(:created_at.desc)
    end

    def self.process_search_results(search, &block)
      posts = []
      search.fetch['results'].each do |hash|
        user   = Faux::User.new(hash['from_user_id'], hash['from_user'], hash['profile_image_url'])
        posts << Faux::Post.new(hash['id'], hash['text'], user, hash['created_at'])
      end
      process_tweets(posts, &block)
    end

    def self.process_tweets(tweets, &block)
      return nil if tweets.empty?
      users = {}
      posts = []
      tweets.each do |s|
        users[s.user.id.to_i] = {:login => s.user.screen_name, :avatar_url => s.user.profile_image_url}
        posts << {:body => s.text, :user_id => s.user.id, :created_at => Time.parse(s.created_at).utc, :external_id => s.id}
      end

      existing_users = User.where(:external_id => users.keys).to_a
      Sequel::Model.db.transaction do
        process_users(users, existing_users)
        process_posts(posts, users, &block)
      end
    end

    # replace user hash values with saved user records
    def self.process_users(users, existing_users)
      user_ids = users.keys
      existing_users.each do |existing|
        user_ids.delete existing.external_id
        process_user users, existing
      end

      user_ids.each do |external_id|
        process_user users, User.new(:external_id => external_id)
      end
    end

    def self.process_user(users, user)
      users[user.external_id].each do |key, value|
        user.send("#{key}=", value)
      end
      user.save!
      users[user.external_id] = user
    end

    def self.process_posts(posts, users, &block)
      posts.reverse!
      posts.each do |attributes|
        user = users[attributes.delete(:user_id).to_i]
        post = Post.new(:user_id => user.id)
        attributes.each do |key, value|
          post.send("#{key}=", value)
        end
        post.body    = post.body.unpack("U*").map! { |s| s > 127 ? "&##{s};" : s.chr }.join
        post.visible = !! (!block || block.call(user, post))
        post.save
        post.save_hash_tags
      end
    end

    def score_from(downcased_body, words)
      return 0 if words.nil?
      score = 0
      words = words.dup
      words.each do |key|
        this_score = key =~ /^#/ ? 2 : 1 # hash keywords worth 2 points
        score += this_score if downcased_body =~ %r{(^|\s|\W)#{key}($|\s|\W)}
      end
      score
    end
  end
end