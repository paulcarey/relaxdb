require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::Query do

  describe "#view_name" do

    it "should match a single key attribute" do
      q = RelaxDB::SortedByView.new("", :foo)
      q.view_name.should == "all_by_foo"
    end
    
    it "should match key attributes" do
      q = RelaxDB::SortedByView.new("", :foo, :bar)
      q.view_name.should == "all_by_foo_and_bar"
    end
  end
  
  describe "#view_path" do
    
    it "should list design document and view name" do
      q = RelaxDB::Query.new("Zenith", "mount")
      q.view_path.should == "_view/Zenith/mount"
    end
    
    it "should contain URL and JSON encoded key when the key has been set" do
      q = RelaxDB::Query.new("Zenith", "mount")
      q.key("olympus")
      q.view_path.should == "_view/Zenith/mount?key=%22olympus%22"
    end
    
    it "should honour startkey, endkey and count" do
      q = RelaxDB::Query.new("Zenith", "all_by_name_and_height")
      q.startkey(["olympus"]).endkey(["vesuvius", 3600]).count(100)
      q.view_path.should == "_view/Zenith/all_by_name_and_height?startkey=%5B%22olympus%22%5D&endkey=%5B%22vesuvius%22%2C3600%5D&count=100"
    end
        
    it "should specify the key as the empty string if key was set to nil" do
      q = RelaxDB::Query.new("", "")
      q.key(nil)
      q.view_path.should == "_view//?key=%22%22"
    end
    
  end  
      
end
