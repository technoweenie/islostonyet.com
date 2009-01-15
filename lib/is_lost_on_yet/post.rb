module IsLOSTOnYet
  class Post < Sequel.Model(:posts)
    many_to_one :user, :class => "IsLOSTOnYet::User"

    def self.find_updates(page = 1)
      filtered_for_updates.where(:visible => true).paginate(page, 30)
    end

    def self.find_replies(page = 1)
      filtered_for_replies.where(:visible => true).paginate(page, 30)
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
          post # .set_tags
        end
      end
    end

    def self.latest_update
      filtered_for_updates.where(:visible => true).select(:external_id).first
    end

    def self.latest_reply
      filtered_for_replies.where(:visible => true).select(:external_id).first
    end

    # a @reply tweet
    def reply?
      body.strip =~ /^@/
    end

    # A tweet from a user asking the twitter bot if the show is on
    def inquiry?
      body.strip =~ /^@#{IsLOSTOnYet.twitter_login}\s*\?$/i
    end

    def visible?
      visible == true || visible == 1
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

    def self.process_tweets(tweets, &block)
      return nil if tweets.empty?
      users = {}
      posts = []
      tweets.reverse!
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
      posts.each do |attributes|
        user = users[attributes.delete(:user_id).to_i]
        post = Post.new(:user_id => user.id)
        attributes.each do |key, value|
          post.send("#{key}=", value)
        end
        post.visible = !! (!block || block.call(user, post))
        post.save
      end
    end
  end
end