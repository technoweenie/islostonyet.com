require File.join(File.dirname(__FILE__), 'test_helper')

class PostTest < Test::Unit::TestCase
  describe "Post#process_updates" do
    before :all do
      @twitter   = Object.new
      @twit_user = Faux::User.new(1, 'lostie', 'http://avatar')
      @twit_post = Faux::Post.new(1, 'hi', @twit_user, 'Sun Jan 04 23:04:16 UTC 2009')
      stub(IsLOSTOnYet).twitter { @twitter }
    end

    describe "without existing user" do
      before :all do
        cleanup IsLOSTOnYet::Post, IsLOSTOnYet::User
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
        cleanup IsLOSTOnYet::Post, IsLOSTOnYet::User
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
end