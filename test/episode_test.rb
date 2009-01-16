require File.join(File.dirname(__FILE__), 'test_helper')

class EpisodeTest < Test::Unit::TestCase
  before :all do
    IsLOSTOnYet.load_episodes :sample
  end

  it "parses season from code" do
    IsLOSTOnYet::Episode.new("s50e40").season.should == 50
  end

  it "parses episode number from code" do
    IsLOSTOnYet::Episode.new("s50e40").number.should == 40
  end

  it "parses episode path from code" do
    IsLOSTOnYet::Episode.new("s50e40").path.should == '/s50/e40'
  end

  describe "IsLOSTOnYet" do
    describe "when date is before all episodes" do
      before :all do
        @date = Time.utc(2008, 1, 21)
      end

      it "#current_and_next_episodes returns no current episode" do
        IsLOSTOnYet.current_and_next_episodes(@date).map! { |e| e.nil? ? e : e.to_s }.should == [nil, 's4e1']
      end

      it "#answer returns 'no' answer" do
        IsLOSTOnYet.answer(@date).result.should == {:answer => :no, :reason => "Season 4 begins on 22 January 2008 at 09:00PM EST"}
      end
    end

    describe "when date is a month after one episode and before the next" do
      before :all do
        @date = Time.utc(2009, 1, 21)
      end

      it "#current_and_next_episodes returns old current episode" do
        IsLOSTOnYet.current_and_next_episodes(@date).map! { |e| e.nil? ? e : e.to_s }.should == ['s4e1', 's5e1']
      end

      it "#answer returns 'no' answer" do
        IsLOSTOnYet.answer(@date).result.should == {:answer => :no, :reason => "Season 5 begins on 21 January 2009 at 09:00PM EST"}
      end
    end

    describe "when date is between episodes" do
      before :all do
        @date = Time.utc(2009, 1, 23)
      end

      it "#current_and_next_episodes returns next and current episode" do
        IsLOSTOnYet.current_and_next_episodes(@date).map! { |e| e.nil? ? e : e.to_s }.should == ['s5e1', 's5e2']
      end

      it "#answer returns 'yes' answer" do
        IsLOSTOnYet.answer(@date).result.should == {:answer => :yes, :reason => "Season 5, episode 2 airs on 28 January 2009 at 09:00PM EST"}
      end
    end

    describe "when date less than 1 month after last episode" do
      before :all do
        @date = Time.utc(2009, 2, 1)
      end

      it "#current_and_next_episodes returns no next episode" do
        IsLOSTOnYet.current_and_next_episodes(@date).map! { |e| e.nil? ? e : e.to_s }.should == ['s5e2', nil]
      end

      it "#answer returns 'yes' answer" do
        IsLOSTOnYet.answer(@date).result.should == {:answer => :yes, :reason => "Season 5, episode 2 aired on 28 January 2009 at 09:00PM EST"}
      end
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

    it "indexes episodes by season" do
      season_5 = [IsLOSTOnYet.episodes[1], IsLOSTOnYet.episodes[0]]
      IsLOSTOnYet.season(:s5).should  == season_5
      IsLOSTOnYet.season('s5').should == season_5
      IsLOSTOnYet.season(5).should    == season_5
    end
  end
end