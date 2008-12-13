require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::Document do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end
      
  describe ".new" do 
    
    it "should create an object with an id" do
      Atom.new._id.should_not be_nil
    end
    
    it "should create an object with a nil revision" do
      Atom.new._rev.should be_nil
    end
        
    it "should convert attributes that end in _at to Times" do
      now = Time.now
      p = Post.new(:viewed_at => now).save
      p = RelaxDB.load(p._id)
      p.viewed_at.class.should == Time
      p.viewed_at.should be_close(now, 1)
    end
    
    it "will silently ignore parameters that don't specify class attributes" do
      # Consider this a feature or bug. It allows an object containing both request params
      # and superflous data to be passed directly to a constructor.
      Post.new(:foo => "").save
    end  
    
  end
      
  describe "#to_json" do
    
    it "should not output nil attributes" do
      Atom.new.to_json.should_not include("rev")
    end
    
    it "should convert times to '%Y/%m/%d %H:%M:%S +0000' format" do
      s = Time.at(0)
      p = Primitives.new(:created_at => s).save
      json = RelaxDB.get(p._id)
      json["created_at"].should == "1970/01/01 00:00:00 +0000"
    end
    
  end
  
  describe "#save" do
    
    it "should set an object's revision" do
      p = Atom.new.save
      p._rev.should_not be_nil
    end
    
    it "should result in an object considered saved" do
      Atom.new.save.should_not be_unsaved
    end
    
    it "should be invokable multiple times" do
      p = Atom.new
      p.save
      p.save      
    end
    
    it "should set created_at when first saved" do
      now = Time.now
      created_at = Post.new.save.created_at
      now.should be_close(created_at, 1)  
    end
    
    it "should set created_at when first saved unless supplied to the constructor" do
      back_then = Time.now - 1000
      p = Post.new(:created_at => back_then).save
      p.created_at.should be_close(back_then, 1)
    end
        
  end
  
  describe "user defined property reader" do
    
    it "should not effect normal operation" do
      o = BespokeReader.new(:val => 101).save
      o = RelaxDB.load o._id
      o.val.should == 106
    end
    
    it "should not modify internal state" do
      o = BespokeReader.new(:val => 101).save
      o = RelaxDB.load o._id
      o.instance_variable_get(:@val).should == 101
    end
            
  end

  describe "user defined property writer" do
    
    it "should not be used" do
      o = BespokeWriter.new(:val => 101).save
      o = RelaxDB.load o._id
      o.val.should == 81
    end
        
  end
  
  describe "loaded objects" do
    
    it "should contain state as when saved" do
      now = Time.now
      p = Primitives.new(:str => "foo", :num => 19.30, :true_bool => true, :false_bool => false, :created_at => now).save
      p = RelaxDB.load(p._id)
      p.str.should == "foo"
      p.num.should == 19.30
      p.true_bool.should be_true
      p.false_bool.should_not be_true
      p.created_at.should be_close(now, 1)
      p.empty.should be_nil
    end
    
    it "should be saveable" do
      a = Atom.new.save
      a = RelaxDB.load(a._id)
      a.save
    end
    
  end
  
  describe "#destroy" do  
    
    it "should delete the corresponding document from CouchDB" do
      p = Atom.new.save.destroy!
      lambda { RelaxDB.load(p._id) }.should raise_error
    end

    it "should prevent the object from being resaved" do
      p = Atom.new.save.destroy!
      lambda { p.save }.should raise_error
    end
    
    it "will result in undefined behaviour when invoked on unsaved objects" do
      lambda { Atom.new.destroy! }.should raise_error
    end
  
  end
  
  describe "#all.destroy!" do
  
    it "should delete from CouchDB all documents of the corresponding class" do
      Atom.new.save
      Post.new.save
      Post.new.save
      Post.all.destroy!
      Post.all.should be_empty
      Atom.all.size.should == 1
    end
  
  end
  
  describe "==" do
    
    it "should define equality based on CouchDB id" do
      i1 = Atom.new.save
      i2 = Atom.new.save
      i3 = RelaxDB.load(i1._id)
      i1.should_not == i2
      i1.should == i3
    end
    
    it "should return false when passed a nil object" do
      (Atom.new == nil).should_not be_true
    end
    
  end
  
  describe ".all" do
  
    it "should return all instances of that class" do
      Photo.new.save
      Rating.new.save
      Rating.new.save
      Rating.all.size.should == 2      
    end
  
    it "should return an empty array when no instances exist" do
      Atom.all.should be_an_instance_of(Array)
      Atom.all.should be_empty
    end
    
  end
  
  describe ".all.size" do
    
    it "should return the total number of docs" do
      docs = []
      100.times { docs << Atom.new }
      RelaxDB.bulk_save(*docs)
      Atom.all.size.should == 100
    end
    
    it "should return 0 when no docs exist" do
      Atom.all.size.should == 0
    end
    
  end
  
  describe ".all.sorted_by" do
  
    it "should sort ascending by default" do
      Post.new(:content => "b").save
      Post.new(:content => "a").save
      posts = Post.all.sorted_by(:content)
      posts[0].content.should == "a"
      posts[1].content.should == "b"
    end

    it "should sort desc when specified" do
      Post.new(:content => "a").save
      Post.new(:content => "b").save
      posts = Post.all.sorted_by(:content) { |q| q.descending(true) }
      posts[0].content.should == "b"
      posts[1].content.should == "a"
    end
  
    it "should sort date attributes lexicographically" do
      t = Time.new
      Post.new(:viewed_at => t+1000, :content => "late").save
      Post.new(:viewed_at => t, :content => "early").save
      posts = Post.all.sorted_by(:viewed_at)
      posts[0].content.should == "early"
      posts[1].content.should == "late"
    end
    
    it "should return the count when queried with reduce=true" do
      docs = []
      100.times { |i| docs << Primitives.new(:num => i) }
      RelaxDB.bulk_save(*docs)
      # Create the view
      Primitives.all.sorted_by(:num)
      res = RelaxDB.view("Primitives", "all_sorted_by_num") { |q| q.reduce(true) }
      count = RelaxDB.reduce_result(res)
      count.should == 100
    end
    
    describe "results" do

      it "should be retrievable by exact criteria" do
        Post.new(:subject => "foo").save
        Post.new(:subject => "foo").save
        Post.new(:subject => "bar").save
        Post.all.sorted_by(:subject) { |q| q.key("foo") }.size.should == 2
      end

      it "should be retrievable by relative criteria" do
        Rating.new(:stars => 1).save
        Rating.new(:stars => 5).save
        Rating.all.sorted_by(:stars) { |q| q.endkey(3) }.size.should == 1
      end

      it "should be retrievable by combined criteria" do
        User.new(:name => "paul", :age => 28).save
        User.new(:name => "paul", :age => 72).save
        User.new(:name => "atlas", :age => 99).save
        User.all.sorted_by(:name, :age) { |q| q.startkey(["paul",0 ]).endkey(["paul", 50]) }.size.should == 1
      end

      it "should be retrievable by combined criteria where not all docs contain all attributes" do
        User.new(:name => "paul", :age => 28).save
        User.new(:name => "paul", :age => 72).save
        User.new(:name => "atlas").save
        User.all.sorted_by(:name, :age) { |q| q.startkey(["paul",0 ]).endkey(["paul", 50]) }.size.should == 1
      end
      
      it "should be retrievable by a multi key post" do
        5.times { |i| Primitives.new(:num => i).save }
        ps = Primitives.all.sorted_by(:num) { |q| q.keys([0, 4]) }
        ps.map { |p| p.num }.should == [0, 4]
      end

    end
    
  end  
  
  describe "defaults" do
    
    it "should be set on initialisation" do
      r = Rating.new
      r.stars.should == 5
    end
    
    it "should be saved" do
      r = Rating.new.save
      RelaxDB.load(r._id).stars.should == 5
    end

    it "should be ignored once overwritten" do
      r = Rating.new
      r.stars = nil
      r.save
      RelaxDB.load(r._id).stars.should be_nil
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
  
  describe "validator" do
    
    it "should prevent an object from being saved if it evaluates to false" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { false }
      end
      r.new.save.should be_false
    end
        
    it "should prevent an object from being saved if it throws an exception" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { raise "foo" }
      end
      r.new.save.should be_false
    end

    it "should pass the property value to the validator" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { |tu| tu >=0 && tu < 3 }
      end
      r.new(:thumbs_up => 2).save.should be
      r.new(:thumbs_up => 3).save.should be_false
    end

    it "should add the validation error message if supplied, on failure" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { false }, :validation_msg => "Too many thumbs"
      end
      x = r.new
      x.save
      x.errors[:thumbs_up].should == "Too many thumbs"
    end
    
    it "should perform all validations" do
      r = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { false }, :validation_msg => "oof"
        property :bar, :validator => lambda { false }, :validation_msg => "rab"
      end
      x = r.new
      x.save
      x.errors[:foo].should == "oof"
      x.errors[:bar].should == "rab"
    end
    
    it "should prevent saving unless all validations pass" do
      r = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { false }
        property :bar, :validator => lambda { true }
      end
      x = r.new
      x.save.should == false
    end
    
    it "may be a proc" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { false }
      end
      r.new.save.should be_false      
    end
    
    it "may be a method" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => :count_em
        def count_em
          false
        end
      end
      r.new.save.should be_false
    end
    
  end
  
end