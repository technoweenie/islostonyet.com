require File.join(File.dirname(__FILE__), 'test_helper')
class TaggingTest < Test::Unit::TestCase
  describe "parsing Post hash tags" do
    before :all do
      cleanup IsLOSTOnYet::Post, IsLOSTOnYet::Tag, IsLOSTOnYet::Tagging
      transaction do
        IsLOSTOnYet::Tag.create(:name => 'jack')
        @post = IsLOSTOnYet::Post.new(:user_id => 1, :external_id => '1', :body => "a b #s1e5 #SAYID! #jack? #Kate.", :created_at => Time.utc(2000, 1, 1))
        @post.save
      end
    end

    it "#hash_tags parses hash tags from #body" do
      @post.hash_tags.should == %w(s1e5 sayid jack kate)
    end

    it "#save_hash_tags" do
      old_tags_count     = IsLOSTOnYet::Tag.count
      old_taggings_count = IsLOSTOnYet::Tagging.count
      @post.save_hash_tags
      IsLOSTOnYet::Tag.count.should     == old_tags_count     + 3
      IsLOSTOnYet::Tagging.count.should == old_taggings_count + 4
      @post.reload.tag.should == "[jack] [kate] [s1e5] [sayid]"
    end
  end

  describe "Post#find_by_tags" do
    before :all do
      cleanup IsLOSTOnYet::Post, IsLOSTOnYet::Tag, IsLOSTOnYet::Tagging
      transaction do
        @post1 = IsLOSTOnYet::Post.new(:user_id => 1, :external_id => '1', :body => "#s1e1 #jack", :created_at => Time.utc(2000, 1, 1), :visible => true)
        @post2 = IsLOSTOnYet::Post.new(:user_id => 1, :external_id => '2', :body => "#s1e2 #jack", :created_at => Time.utc(2000, 1, 2), :visible => true)
        @post3 = IsLOSTOnYet::Post.new(:user_id => 1, :external_id => '3', :body => "abc",         :created_at => Time.utc(2000, 1, 3), :visible => true)
        [@post1, @post2, @post3].each { |p| p.save ; p.save_hash_tags }
      end
    end

    it "finds posts by single tag" do
      IsLOSTOnYet::Post.find_by_tags(%w(jack)).map { |p| p.external_id }.should == [@post2, @post1].map { |p| p.external_id }
    end

    it "finds posts by multiple tags" do
      IsLOSTOnYet::Post.find_by_tags(%w(jack s1e1)).map { |p| p.external_id }.should == [@post1].map { |p| p.external_id }
    end
  end
end