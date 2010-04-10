require File.dirname(__FILE__) + '/spec_helper.rb'

# A little naiive, needs quite a bit more thought and work

describe RelaxDB::Document, "callbacks" do
  
  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec" rescue "ok"
    RelaxDB.use_db "relaxdb_spec"
  end
  
  describe "before_save" do
  
    it "should be run before the object is saved" do
      c = Class.new(RelaxDB::Document) do
        before_save lambda { |s| s.gem += 1 if s.unsaved? }
        property :gem
      end
      p = c.new(:gem => 5).save
      p.gem.should == 6
    end
    
    it "should prevent the object from being saved if it returns false" do
      c = Class.new(RelaxDB::Document) do
        before_save lambda { |o| false }
      end
      c.new.save.should == false
    end
    
    it "should add a description to errors when false is returned" do
      c = Class.new(RelaxDB::Document) do
        before_save lambda { |o| false }
      end
      x = c.new
      x.save
      x.errors[:before_save].should be
    end    

    it "should not prevent the object from being saved if it returns nil" do
      c = Class.new(RelaxDB::Document) do
        before_save lambda { |o| nil }
      end
      c.new.save!
    end
    
    it "may be a proc" do
      c = Class.new(RelaxDB::Document) do
        before_save lambda { |o| false }
      end
      c.new.save.should == false      
    end
    
    it "may be a method" do
      c = Class.new(RelaxDB::Document) do
        before_save :never
        def never; false; end
      end
      c.new.save.should == false
    end
    
  end
  
  describe "after_save" do
    
    it "should be run after the object is saved" do
      c = Class.new(RelaxDB::Document) do
        after_save lambda { |s| s.gem +=1 unless s.unsaved? }
        property :gem
      end
      p = c.new(:gem => 5).save
      p.gem.should == 6
    end
    
  end

end