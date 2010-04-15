require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "Inheritance" do
  
  before(:each) do
    setup_test_db
  end
  
  describe "properties" do

    it "should by inherited from a parent document" do
      d = SubDescendant.new(:x => 1).save!
      RelaxDB.reload(d).x.should == 1
    end
    
    it "should store its own properties" do
      r = RichDescendant.new(:x => 1, :foo => :bar).save!
      RelaxDB.reload(r).x.should == 1
      RelaxDB.reload(r).foo.should == "bar"
    end
    
    it "validators should behave as normal" do
      d = SubDescendant.new(:y => false)
      d.save.should be_false
      d.errors[:y].should == "Uh oh"
    end
    
  end      
    
  describe "_all views" do
    
    it "should be rewritten" do
      a = Ancestor.new(:x => 0).save!
      d = Descendant.new(:x => 1).save!

      Ancestor.all.load!.should include(a, d)
      Descendant.all.load!.should == [d]
    end

    it "should function with inheritance trees" do
      Inh::X.new.save!
      
      Inh::Y.new.save!
      Inh::Y1.new.save!
      
      Inh::Z.new.save!
      Inh::Z1.new.save!
      Inh::Z2.new.save!
      
      Inh::X.all.size.should == 6
      Inh::Y.all.size.should == 2
      Inh::Y1.all.size.should == 1
      Inh::Z.all.size.should == 3
      Inh::Z1.all.size.should == 1
      Inh::Z2.all.size.should == 1
    end
    
  end
  
  describe "_by views" do
    
    it "should be rewritten for ancestors and generated for descendants" do
      a = Ancestor.new(:x => 0).save!
      d = Descendant.new(:x => 1).save!
      
      Ancestor.by_x.should == [a, d]
      Descendant.by_x.should == [d]
    end
    
  end
  
  describe "derived properties" do
    
    it "should be stored" do
      u = User.new(:_id => "foo", :name => "u").save!
      s = SubDescendant.new(:user => u).save!
      r = RichDescendant.new(:user => u, :ukulele => u).save!
      
      RelaxDB.reload(s).user_name.should == "u"
      RelaxDB.reload(r).user_name.should == "u"
      RelaxDB.reload(r).ukulele_name.should == "u"
    end
    
  end

  describe "references" do
    
    it "should function as normal" do
      u = User.new(:name => "u").save!
      s = SubDescendant.new(:user => u).save!
      r = RichDescendant.new(:user => u).save!
      
      RelaxDB.reload(s).user.name.should == "u"
      RelaxDB.reload(r).user.name.should == "u"
    end
    
  end
    
end