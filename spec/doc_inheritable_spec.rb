require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "inheritance" do
  
  before(:each) do
    setup_test_db
  end
      
  it "should inherit from a parent document" do
    p = PrimitivesChild.new(:num => 1).save!
    RelaxDB.reload(p).num.should == 1
  end
    
  describe "all views" do
    
    it "should be rewritten" do
      a = Ancestor.new(:x => 0).save!
      d = Descendant.new(:x => 1).save!

      Ancestor.all.should == [a, d]
      Descendant.all.should == [d]
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
  
  describe "by views" do
    
    it "should be rewritten" do
      a = Ancestor.new(:x => 0).save!
      d = Descendant.new(:x => 1).save!
      
      Ancestor.by_x.should == [a, d]
      Descendant.by_x.should == [d]
    end
    
  end
  
  # test properties
  # test belongs to
  # test derived properties (belongs_to only for now)
  # test all
  # test view_by
  # test validation & validation_msg
  # test tree inheritance e.g x -> y; y -> y1 ; x -> z; z -> z1; z -> z2;
  
end