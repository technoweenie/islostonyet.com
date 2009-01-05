require File.join(File.dirname(__FILE__), 'test_helper')

class EpisodeTest < Test::Unit::TestCase
  before :all do
    IsLOSTOnYet.load_episodes :sample
  end

  describe "IsLOSTOnYet#answer" do
    it "returns next scheduled episode when date is before all episodes" do
      stub(Time).now { Time.utc(2008, 1, 21) }
      IsLOSTOnYet.answer.should == {:answer => :no}
    end

    it "returns next scheduled episode when date is a month after one episode and before the next" do
      stub(Time).now { Time.utc(2009, 1, 21) }
      IsLOSTOnYet.answer.should == {:answer => :no}
    end

    it "returns current and next scheduled episode when date is between episodes" do
      stub(Time).now { Time.utc(2009, 1, 23) }
      IsLOSTOnYet.answer.should == {:answer => :yes}
    end

    it "returns current episode when date < 1.month after last episode" do
      stub(Time).now { Time.utc(2009, 2, 1) }
      IsLOSTOnYet.answer.should == {:answer => :yes}
    end
  end

  describe "Episode#load" do
    it "reads episodes from yml file" do
      IsLOSTOnYet.episodes.size.should == 3
      IsLOSTOnYet.episodes.first.class.should == IsLOSTOnYet::Episode
    end

    it "stores episode code" do
      IsLOSTOnYet.episodes[1].code.should == 's5e1'
      IsLOSTOnYet.episodes[0].code.should == 's5e2'
    end

    it "stores episode title" do
      IsLOSTOnYet.episodes[1].title.should =~ /Left/
      IsLOSTOnYet.episodes[0].title.should =~ /Lie/
    end

    it "stores episode air_date" do
      IsLOSTOnYet.episodes[1].air_date.should == Time.utc(2009, 1, 22, 2)
      IsLOSTOnYet.episodes[0].air_date.should == Time.utc(2009, 1, 29, 2)
    end
  end

  describe "IsLOSTOnYet#load_episodes" do
    it "loads episodes from YAML" do
      IsLOSTOnYet.episodes.should == IsLOSTOnYet::Episode.load(:sample)
    end

    it "indexes episodes by code" do
      IsLOSTOnYet.episode(:s5e1).should == IsLOSTOnYet.episodes[1]
    end
  end
end