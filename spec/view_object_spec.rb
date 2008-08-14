require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::ViewObject do
  
  describe ".new" do 
    
    it "should provide readers for the object passed in the hash" do
      data = { :name => "chaise", :variety => "longue" }
      obj = RelaxDB::ViewObject.new(data)
      obj.name.should == "chaise"
      obj.variety.should == "longue"
    end
    
    it "should try to convert objects ending in _at to a time" do
      now = Time.now
      data = { :ends_at => now.to_s }
      obj = RelaxDB::ViewObject.new(data)
      obj.ends_at.should be_close(now, 1)
    end
    
  end
  
  describe ".create" do
    
    it "should return an array of view objects when passed an array" do
      data = [ {:half_life => 2}, {:half_life => 16} ]
      obj = RelaxDB::ViewObject.create(data)
      obj.size.should == 2
      obj[0].half_life.should == 2
      obj[1].half_life.should == 16
    end

    it "should return a view object when passed a hash" do
      data = {:half_life => 32}
      obj = RelaxDB::ViewObject.create(data)
      obj.half_life.should == 32
    end
    
    it "should return a simple value when passed a primitive" do
      obj = RelaxDB::ViewObject.create(10)
      obj.should == 10
    end
    
  end
  
end
