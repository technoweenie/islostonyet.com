module IsLOSTOnYet
  class Post < Sequel.Model(:posts)
    
    def self.process_updates
      args  = [:user]
      process_tweets(IsLOSTOnYet.twitter.timeline(*args))
    end

    def self.process_replies
      args  = []
      process_tweets(IsLOSTOnYet.twitter.replies(*args))
    end

  protected
    def self.process_tweets(tweets)
      return nil if tweets.empty?
      users = {}
      posts = []
      tweets.reverse!
      tweets.each do |s|
        users[s.user.id] = {:login => s.user.name, :avatar_url => s.user.profile_image_url}
        posts << {:body => s.text, :user_id => s.user.id, :created_at => Time.parse(s.created_at).utc, :external_id => s.id}
      end

      process_users(users)
      process_posts(posts, users)
    end

    # replace user hash values with saved user records
    def self.process_users(users)
      user_ids = users.keys
      User.where(:external_id => user_ids).each do |existing|
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
      user.save
      users[user.external_id] = user
    end

    def self.process_posts(posts, users)
      posts.each do |attributes|
        post = Post.new(:user_id => users[attributes.delete(:user_id)].id)
        attributes.each do |key, value|
          post.send("#{key}=", value)
        end
        post.save
      end
    end
  end
end