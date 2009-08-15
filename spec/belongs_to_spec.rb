require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::BelongsToProxy do
  
  before(:all) do
    setup_test_db
  end

  describe "belongs_to" do
  
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
      r = Rating.new(:photo_id => p._id).save
      r.photo.should == p
    end        
      
    it "should establish the parent relationship when supplied a parent and saved" do
      p = Photo.new.save
      r = Rating.new
      r.photo = p
      # I'm not saying the following is correct or desired - merely codifying how things stand 
      p.rating.should be_nil 
      r.save
      p.rating.should == r
    end    
  
    it "should establish the parent relationship when supplied a parent id and saved" do
      p = Photo.new.save
      r = Rating.new(:photo_id => p._id).save
      p.rating.should == r
    end        

    it "should return the same object on repeated invocations" do
      p = Photo.new.save
      r = Rating.new(:photo => p).save
      r = RelaxDB.load(r._id)
      r.photo.object_id.should == r.photo.object_id
    end    

    it "should be nullified when the parent is destroyed" do
      r = Rating.new
      p = Photo.new(:rating => r).save
      p.destroy!
      RelaxDB.load(r._id).photo.should be_nil
    end
  
    it "should be preserved across save / load boundary" do
      r = Rating.new
      p = Photo.new(:rating => r).save
      r = RelaxDB.load r._id
      r.photo.should == p
    end    

    it "should be able to reference itself via its parent" do
      r = Rating.new
      p = Photo.new(:rating => r).save
      r = RelaxDB.load r._id
      r.photo.rating.should == r
    end    
    
    it "may be used reciprocally" do
      C1 = Class.new(RelaxDB::Document) do
        belongs_to :c2
      end
      C2 = Class.new(RelaxDB::Document) do
        belongs_to :c1
      end
      i1, i2 = C1.new, C2.new

      i1.c2 = i2
      i1.save!
      i2.c1 = i1
      i2.save!
      
      i1 = RelaxDB.load i1._id
      i1.c2.should == i2
      
      i2 = RelaxDB.load i2._id
      i2.c1.should == i1
    end
    
    describe "validator" do
      
      it "should be passed the _id and object" do
        a = Atom.new(:_id => "atom").save!
        c = Class.new(RelaxDB::Document) do
          belongs_to :foo, :validator => lambda { |foo_id, obj| foo_id.reverse == obj._id }
        end
        c.new(:_id => "mota", :foo => a).save!
      end
      
      it "may be used with a predefined validator" do
        c = Class.new(RelaxDB::Document) do
          belongs_to :foo, :validator => :required
        end
        c.new.save.should be_false
      end

      it "should be provided with a default error message when validation fails" do
        c = Class.new(RelaxDB::Document) do
          belongs_to :foo, :validator => :required
        end
        x = c.new
        x.save
        x.errors[:foo].should_not be_blank
      end
          
    end
    
  end

end
