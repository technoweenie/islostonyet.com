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
    end
  end
end