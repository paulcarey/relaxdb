require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::AllDelegator do
  
  before(:all) do
    setup_test_db
  end

  describe "size" do
  
    it "should return the total count for a given class" do
      docs = (1..101).map { |i| Primitives.new :num => i }
      RelaxDB.bulk_save! *docs
      Primitives.all.size.should == 101
    end
    
  end
  
  describe "all" do
    
    it "should return the ids for the given class" do
      docs = (1..3).map { |i| Primitives.new :_id => "p#{i}" }
      RelaxDB.bulk_save! *docs
      Primitives.all.should == %w(p1 p2 p3)
    end
    
  end
  
  describe "load" do
    
    it "should load all docs for the given class" do
      docs = (1..3).map { |i| Primitives.new :num => i }
      RelaxDB.bulk_save! *docs
      pms = Primitives.all.load
      pms.map { |p| p.num }.inject(&:+).should == 6
    end
    
  end
  
  describe "destroy" do
    
    it "should destroy all docs fot the given class" do
      docs = (1..3).map { |i| Primitives.new :num => i }
      RelaxDB.bulk_save! *docs
      Primitives.all.destroy!
      Primitives.all.load.should == []
    end
    
  end

end
