require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::ReferencesProxy do
  
  before(:all) do
    setup_test_db
  end

  describe "references" do
  
    it "should return nil when accessed before assignment" do
      r = Rating.new
      r.photo.should == nil
    end

    it "should be establishable via constructor attribute" do
      p = Photo.new
      r = Rating.new :photo => p
      r.photo.should == p
    end
    
    it "should be establishable via constructor id" do
      p = Photo.new.save
      r = Rating.new :photo_id => p._id
      r.photo.should == p
    end        
        
    it "should return the same object on repeated invocations" do
      p = Photo.new.save
      r = Rating.new(:photo => p).save
      r = RelaxDB.load(r._id)
      r.photo.object_id.should == r.photo.object_id
    end    
        
    it "may be used reciprocally across save / load boundary" do
      fb, bf = FooBar.new, BarFoo.new

      fb.bf = bf
      fb.save!
      bf.fb = fb
      bf.save!
      
      fb = RelaxDB.load fb._id
      fb.bf.should == bf
      
      bf = RelaxDB.load bf._id
      bf.fb.should == fb
    end
    
    it "should not store the referenced object" do
      p = Photo.new.save!
      r = Rating.new(:photo => p).save!
      
      r = RelaxDB.reload r
      RelaxDB.db.reset_req_count
      
      r.data["photo"].should be_nil
      r.photo.should == p
      
      RelaxDB.db.req_count.should == 1
    end
    
    describe "validator" do
      
      it "should be passed the _id and object" do
        a = Atom.new(:_id => "atom").save!
        c = Class.new(RelaxDB::Document) do
          references :foo, :validator => lambda { |foo_id, obj| foo_id.reverse == obj._id }
        end
        c.new(:_id => "mota", :foo => a).save!
      end
      
      it "may be used with a predefined validator" do
        c = Class.new(RelaxDB::Document) do
          references :foo, :validator => :required
        end
        c.new.save.should be_false
      end

      it "should be provided with a default error message when validation fails" do
        c = Class.new(RelaxDB::Document) do
          references :foo, :validator => :required
        end
        x = c.new
        x.save
        x.errors[:foo].should_not be_blank
      end
          
    end
    
  end

end
