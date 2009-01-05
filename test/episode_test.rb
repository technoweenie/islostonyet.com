require File.join(File.dirname(__FILE__), 'test_helper')

class EpisodeTest < Test::Unit::TestCase
  describe "Episode#load" do
    before :all do
      @episodes = IsLOSTOnYet::Episode.load :sample
    end

    it "reads episodes from yml file" do
      @episodes.size.should == 2
      @episodes.first.class.should == IsLOSTOnYet::Episode
    end

    it "stores episode code" do
      @episodes[1].code.should == 's5e1'
      @episodes[0].code.should == 's5e2'
    end

    it "stores episode title" do
      @episodes[1].title.should =~ /Left/
      @episodes[0].title.should =~ /Lie/
    end

    it "stores episode air_date" do
      @episodes[1].air_date.should == Time.utc(2009, 1, 22, 2)
      @episodes[0].air_date.should == Time.utc(2009, 1, 29, 2)
    end
  end
end