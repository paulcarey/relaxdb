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
  
  it "should rewrite ancestor view_by views" do
    a = Ancestor.new(:x => 0).save!
    d = Descendant.new(:x => 1).save!
    
    Ancestor.all.should == [a, d]
    Descendant.all.should == [d]
  end
  
  # test properties
  # test belongs to
  # test derived properties (belongs_to only for now)
  # test all
  # test view_by
  # test validation & validation_msg
  # test tree inheritance e.g x -> y; y -> y1 ; x -> z; z -> z1; z -> z2;
  
end