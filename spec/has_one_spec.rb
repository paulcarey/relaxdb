require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::HasOneProxy do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end
        
  describe "has_one" do
    
    it "should return nil when accessed before assignment" do
      p = Photo.new
      p.rating.should == nil
    end    
    
    it "should be establishable via a constructor attribute" do
      r = Rating.new
      p = Photo.new :rating => r
      p.rating.should == r
    end

    it "should be establishable via assignment" do
      p = Photo.new
      r = Rating.new
      p.rating = r
      p.rating.should == r
    end
    
    it "should return the same object on repeated invocations" do
      p = Photo.new.save
      p.rating = Rating.new
      p = RelaxDB.load(p._id)
      p.rating.object_id.should == p.rating.object_id
    end
    
    it "should be preserved across load / save boundary" do
      r = Rating.new
      p = Photo.new(:rating => r).save
      p = RelaxDB.load p._id
      p.rating.should == r
    end    
    
    it "should be able reference itself via its child" do
      r = Rating.new
      p = Photo.new(:rating => r).save
      p = RelaxDB.load p._id
      p.rating.photo.should == p
    end        
           
    describe "#=" do

      it "should create a reference from the child to the parent" do
        p = Photo.new
        r = Rating.new
        p.rating = r
        r.photo.should == p
      end

      it "should save the assigned object" do
        p = Photo.new
        r = Rating.new
        p.rating = r
        r.should_not be_unsaved
      end

      it "will not save the parent" do
        p = Photo.new
        r = Rating.new
        p.rating = r
        p.should be_unsaved
      end

      it "should set the target to nil when nil is assigned" do
        p = Photo.new
        p.rating = nil
        p.rating.should be_nil
      end

      it "should nullify any existing relationship in the database" do
        p = Photo.new
        r = Rating.new
        p.rating = r
        p.rating = nil
        RelaxDB.load(r._id).photo.should be_nil
      end

      it "should nullify any existing relationship on a known in-memory object" do
        p = Photo.new
        r = Rating.new
        p.rating = r
        p.rating = nil
        r.photo.should be_nil
      end

      it "will not nullify any existing relationship on unknown in-memory objects" do
        p = Photo.new.save
        r = Rating.new
        p.rating = r
        r_copy = RelaxDB.load(r._id)
        p.rating = nil
        r_copy.photo.should_not be_nil
      end

    end  
           
  end
      
end
