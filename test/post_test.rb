require File.join(File.dirname(__FILE__), 'test_helper')
class PostTest < Test::Unit::TestCase
  describe "Selecting Posts" do
    before :all do
      cleanup IsLOSTOnYet::Post, IsLOSTOnYet::User
      transaction do
        @user1 = IsLOSTOnYet::User.new(:external_id => 1, :login => 'abc', :avatar_url => 'http://abc')
        @user2 = IsLOSTOnYet::User.new(:external_id => 2, :login => 'def', :avatar_url => 'http://def')
        [@user1, @user2].each { |u| u.save }
        @post1 = IsLOSTOnYet::Post.new(:user_id => @user1.id, :external_id => 1, :body => 'a', :created_at => Time.utc(2000, 1, 1))
        @post2 = IsLOSTOnYet::Post.new(:user_id => @user1.id, :external_id => 2, :body => 'b', :created_at => Time.utc(2000, 1, 2))
        @post3 = IsLOSTOnYet::Post.new(:user_id => @user2.id, :episode => 's1e1', :external_id => 3, :body => 'c', :created_at => Time.utc(2000, 1, 3))
        @post4 = IsLOSTOnYet::Post.new(:user_id => @user2.id, :episode => 's2e2', :external_id => 4, :body => 'd', :created_at => Time.utc(2000, 1, 4))
        @post5 = IsLOSTOnYet::Post.new(:user_id => @user2.id, :episode => 's2e1', :external_id => 5, :body => 'e', :created_at => Time.utc(2000, 1, 5))
        [@post1, @post2, @post3, @post4, @post5].each { |p| p.save }
      end
      IsLOSTOnYet.twitter_user = @user1
    end

    it "finds posts by season" do
      IsLOSTOnYet::Post.for_season(:s2).to_a.should == [@post5, @post4]
    end

    it "finds posts by episode" do
      IsLOSTOnYet::Post.for_episode(:s2e2).to_a.should == [@post4]
    end

    it "finds updates" do
      IsLOSTOnYet::Post.find_updates.to_a.should == [@post2, @post1]
    end

    it "finds replies" do
      IsLOSTOnYet::Post.find_replies.to_a.should == [@post5, @post4, @post3]
    end
  end

  describe "Post 'since_id' values" do
    before :all do
      cleanup IsLOSTOnYet::Post, IsLOSTOnYet::User
      transaction do
        @user1 = IsLOSTOnYet::User.new(:external_id => 1, :login => 'abc', :avatar_url => 'http://abc')
        @user2 = IsLOSTOnYet::User.new(:external_id => 2, :login => 'def', :avatar_url => 'http://def')
        [@user1, @user2].each { |u| u.save }
        @post1 = IsLOSTOnYet::Post.new(:user_id => @user1.id, :external_id => 1, :body => 'a', :created_at => Time.utc(2000, 1, 1))
        @post2 = IsLOSTOnYet::Post.new(:user_id => @user1.id, :external_id => 2, :body => 'b', :created_at => Time.utc(2000, 1, 2))
        @post3 = IsLOSTOnYet::Post.new(:user_id => @user2.id, :external_id => 3, :body => 'c', :created_at => Time.utc(2000, 1, 3))
        @post4 = IsLOSTOnYet::Post.new(:user_id => @user2.id, :external_id => 4, :body => 'd', :created_at => Time.utc(2000, 1, 4))
        [@post1, @post2, @post3, @post4].each { |p| p.save }
      end
      IsLOSTOnYet.twitter_user = @user1
    end

    before do
      @twitter = Object.new
      stub(IsLOSTOnYet).twitter { @twitter }
    end

    it "finds latest external_id for updates" do
      IsLOSTOnYet::Post.latest_update.external_id.should == 2
    end

    it "finds latest external_id for replies" do
      IsLOSTOnYet::Post.latest_reply.external_id.should == 4
    end

    it "uses latest update external_id when processing updates" do
      mock(@twitter).timeline(*[:user, {:since_id => 2}]) { [] }
      IsLOSTOnYet::Post.process_updates
    end

    it "uses latest reply external_id when processing replies" do
      mock(@twitter).replies(*[{:since_id => 4}]) { [] }
      IsLOSTOnYet::Post.process_replies
    end

    it "uses no update external_id when processing first updates" do
      stub(IsLOSTOnYet::Post).latest_update { nil }
      mock(@twitter).timeline(*[:user]) { [] }
      IsLOSTOnYet::Post.process_updates
    end

    it "uses no reply external_id when processing first replies" do
      stub(IsLOSTOnYet::Post).latest_reply { nil }
      mock(@twitter).replies(*[]) { [] }
      IsLOSTOnYet::Post.process_replies
    end
  end

  describe "Post#process_updates" do
    before :all do
      cleanup IsLOSTOnYet::Post, IsLOSTOnYet::User
      @twitter   = Object.new
      @twit_user = Faux::User.new(1, IsLOSTOnYet.twitter_login, 'http://avatar')
      @twit_post = Faux::Post.new(1, 'hi', @twit_user, 'Sun Jan 04 23:04:16 UTC 2009')
      stub(IsLOSTOnYet).twitter { @twitter }
      IsLOSTOnYet.twitter_user = nil
    end

    describe "without existing user" do
      before :all do
        stub(@twitter).timeline(:user) { [@twit_post] }

        IsLOSTOnYet::Post.process_updates

        @user = IsLOSTOnYet::User.find(:external_id => @twit_user.id)
        @post = IsLOSTOnYet::Post.find(:external_id => @twit_post.id)
      end

      it "creates user" do
        @user.login.should      == @twit_user.name
        @user.avatar_url.should == @twit_user.profile_image_url
      end

      it "creates post" do
        @post.body.should       == @twit_post.text
        @post.created_at.should == Time.utc(2009, 1, 4, 23, 4, 16)
      end

      it "links post to user" do
        @post.user_id.should == @user.id
      end
    end

    describe "with existing user" do
      before :all do
        stub(@twitter).timeline(:user) { [@twit_post] }

        @user = IsLOSTOnYet::User.new(:external_id => @twit_user.id, :login => 'abc', :avatar_url => 'http://')
        @user.save

        IsLOSTOnYet::Post.process_updates

        @user.reload
        @post = IsLOSTOnYet::Post.find(:external_id => @twit_post.id)
      end

      it "uses existing user" do
        IsLOSTOnYet::User.count.should == 1
      end

      it "updates user attributes" do
        @user.login.should      == @twit_user.name
        @user.avatar_url.should == @twit_user.profile_image_url
      end

      it "creates post" do
        @post.body.should       == @twit_post.text
        @post.created_at.should == Time.utc(2009, 1, 4, 23, 4, 16)
      end

      it "links post to user" do
        @post.user_id.should == @user.id
      end
    end
  end

  describe "Post#process_replies" do
    before :all do
      @twitter    = Object.new
      @twit_users = [Faux::User.new(1, 'bob', 'http://bob'), Faux::User.new(2, 'fred', 'http://fred')]
      @twit_posts = [Faux::Post.new(1, 'hi1', @twit_users.first, 'Sun Jan 04 23:04:16 UTC 2009'), Faux::Post.new(2, 'hi2 #s1e2', @twit_users.last, 'Sun Jan 04 23:04:16 UTC 2009')]
      stub(IsLOSTOnYet).twitter { @twitter }

      cleanup IsLOSTOnYet::Post, IsLOSTOnYet::User

      @user1 = IsLOSTOnYet::User.new(:external_id => @twit_users[0].id, :login => 'abc', :avatar_url => 'http://')
      @user1.save

      stub(@twitter).replies { @twit_posts.dup }
      stub(IsLOSTOnYet).current_and_next_episodes { ['s1e1', nil] }

      IsLOSTOnYet::Post.process_replies

      @user1.reload
      @user2 = IsLOSTOnYet::User.find(:external_id => @twit_users[1].id)
      @post1 = IsLOSTOnYet::Post.find(:external_id => @twit_posts[0].id)
      @post2 = IsLOSTOnYet::Post.find(:external_id => @twit_posts[1].id)
    end

    it "users existing user" do
      IsLOSTOnYet::User.count.should == 2
      @user1.login.should            == @twit_users[0].name
      @user1.avatar_url.should       == @twit_users[0].profile_image_url
    end

    it "creates user" do
      @user2.login.should      == @twit_users[1].name
      @user2.avatar_url.should == @twit_users[1].profile_image_url
    end

    it "creates posts" do
      IsLOSTOnYet::Post.count.should == 2
      @post1.body.should             == @twit_posts[0].text
      @post1.episode.should          == 's1e1'
      @post1.created_at.should       == Time.utc(2009, 1, 4, 23, 4, 16)
    end

    it "allows custom episodes set with hashtag" do
      @post2.episode.should == 's1e2'
    end

    it "links post to user" do
      @post1.user_id.should == @user1.id
      @post2.user_id.should == @user2.id
    end
  end
end