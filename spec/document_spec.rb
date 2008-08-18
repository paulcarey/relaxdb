require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::Document do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984, :db => "relaxdb_spec_db")  
  end

  before(:each) do
    RelaxDB.db.delete
    RelaxDB.db.put
  end
  
  describe ".new" do 
    
    it "should create an object with an id" do
      p = User.new
      p._id.should_not be_nil
    end
    
    it "should create an object with a nil revision" do
      User.new._rev.should be_nil
    end
        
    it "should convert attributes that end in _at to dates" do
      now = Time.now
      p = Post.new(:viewed_at => now).save
      p = RelaxDB.load(p._id)
      p.viewed_at.class.should == Time
      p.viewed_at.should be_close(now, 1)
    end  
    
  end
      
  describe "#to_json" do
    
    it "should not output nil attributes" do
      User.new.to_json.should_not include("rev")
    end
    
  end
  
  describe "#save" do
    
    it "should set an object's revision" do
      p = User.new.save
      p._rev.should_not be_nil
    end
    
    it "should result in an object considered saved" do
      User.new.save.unsaved.should be_false
    end
    
    it "should be invokable multiple times" do
      p = User.new
      p.save
      p.save      
    end
    
    it "should set created_at on creation" do
      now = Time.now
      created_at = Post.new.save.created_at
      now.should be_close(created_at, 1)  
    end
    
    it "should set created_at on creation unless supplied to the constructor" do
      back_then = Time.now - 1000
      p = Post.new(:created_at => back_then).save
      p.created_at.should be_close(back_then, 1)
    end
        
  end
  
  describe "#destroy" do  
    
    it "should delete the object in the database" do
      p = Item.new.save.destroy!
      lambda { RelaxDB.load(p._id) }.should raise_error
    end

    it "should prevent the object from being resaved" do
      p = Item.new.save
      p.destroy!
      lambda { p.save }.should raise_error
    end
    
    it "results in undefined behaviour when invoked on unsaved objects" do
      p = Photo.new
      p.destroy!
      
      d = Dullard.new
      lambda { d.destroy! }.should raise_error
    end
  
  end
  
  describe "==" do
    
    it "should define equality based on CouchDB id" do
      i1 = Item.new.save
      i2 = Item.new.save
      i3 = RelaxDB.load(i1._id)
      i1.should_not == i2
      i1.should == i3
    end
    
    it "should return false when passed a nil object" do
      (Item.new == nil).should_not be_true
    end
    
  end
  
  describe "defaults" do
    
    it "should be set on initialisation" do
      r = Rating.new
      r.shards.should == 50
    end
    
    it "should be saved" do
      r = Rating.new.save
      RelaxDB.load(r._id).shards.should == 50
    end

    it "should be ignored once overwritten" do
      r = Rating.new
      r.shards = nil
      r.save
      RelaxDB.load(r._id).shards.should be_nil
    end    
    
    it "may be a simple value" do
      simple = Class.new(RelaxDB::Document) do 
        property :foo, :default => :bar
      end
      simple.new.foo.should == :bar
    end
      
    it "may be a proc" do
      simple = Class.new(RelaxDB::Document) do 
        property :foo, :default => lambda { :bar }
      end
      simple.new.foo.should == :bar      
    end        
        
  end
  
end