require File.join(File.dirname(__FILE__), 'test_helper')
class TaggingTest < Test::Unit::TestCase
  describe "parsing Post hash tags" do
    it "parses hash tags from #body" do
      IsLOSTOnYet::Post.new(:body => "a b #s1e5 #sayid! #jack? #kate.").hash_tags.should == %w(s1e5 sayid jack kate)
    end
  end
end