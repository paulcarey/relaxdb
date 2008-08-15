require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::Query do

  describe "query api" do

    it "view name should match a single key attribute" do
      q = RelaxDB::SortedByView.new("", :foo)
      q.view_name.should == "all_by_foo"
    end
    
    it "view name should match key attributes" do
      q = RelaxDB::SortedByView.new("", :foo, :bar)
      q.view_name.should == "all_by_foo_and_bar"
    end
    
    it "view_path with params should be correct" do
      q = RelaxDB::Query.new("Zenith", "mount")
      q.view_path.should == "_view/Zenith/mount"
    end
    
    it "view_path should contain JSON encoded key if the key has been set" do
      q = RelaxDB::Query.new("Zenith", "mount")
      q.key("olympus")
      q.view_path.should == "_view/Zenith/mount?key=%22olympus%22"
    end
    
    it "view_path should represent startkey, endkey and count correctly" do
      q = RelaxDB::Query.new("Zenith", "all_by_name_and_height")
      q.startkey(["olympus"]).endkey(["vesuvius", 3600]).count(100)
      q.view_path.should == "_view/Zenith/all_by_name_and_height?startkey=%5B%22olympus%22%5D&endkey=%5B%22vesuvius%22%2C3600%5D&count=100"
    end
        
    it "if key set to nil - it should work as nil - i.e. be used and not return anything" do
      q = RelaxDB::Query.new("", "")
      q.key(nil)
      q.view_path.should == "_view//?key=%22%22"
    end
    
  end  
      
end
