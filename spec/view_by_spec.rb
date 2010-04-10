require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "view_by" do
    
  before(:each) do
    setup_test_db
                                                                      
    docs = (1..10).map { |i| Primitives.new :_id => "id#{i}", :str => i.to_s }
    RelaxDB.bulk_save! *docs
  end
    
  it "should return an array of doc ids for a key" do
    docs = Primitives.by_str :key => "5"
    docs.first.should == "id5"
  end
  
  it "should obey startkey and endkey directives" do
    docs = Primitives.by_str :startkey => "3", :endkey => "6"
    docs.should == %w(id3 id4 id5 id6)
  end
  
  it "should return all when none specified" do
    docs = Primitives.by_str 
    docs.size.should == 10
  end
  
  it "should return arrays that behave normally" do
    p1 = Primitives.by_str :key => "1"
    p2 = Primitives.by_str :key => "2"
    RelaxDB.load!(p1 + p2).map { |p| p.str }.join.should == "12" 
  end
  
  describe "delegator" do
    
    it "should load the returned doc ids" do
      docs = Primitives.by_str :key => "5"
      docs.load!.first.str.should == "5"
    end
    
    it "should load the doc for a single param" do
      res = Primitives.by_str "8"
      res.str.should == "8"
    end
    
    it "should return the delegator when no params given" do
      docs = Primitives.by_str.load!
      docs.map { |d| d.str }.join.length.should == 11
    end
    
  end
    
end