require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::Document do
  
  before(:each) do
    setup_test_db
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
    
    it "will fail on parameters that don't specify class attributes" do
      lambda {
        Post.new :foo => ""
      }.should raise_error
    end  
    
    it "should create a document with a non conflicing state" do
      Atom.new.should_not be_update_conflict
    end
    
  end
  
  describe "#initialize" do
    
    it "may be overridden by inheriting classes" do
      i = Initiative.new(:x => "y").save
      i = RelaxDB.load("y")
      i.x.should == "y"
      i.foo.should == :bar
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

    it "should allow to be called with an options argument, to be compatible with ActiveSupport" do
      s = Time.at(0)
      lambda { s.to_json( :active_support => 'love' ) }.should_not raise_error(ArgumentError)
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
    
    it "should set created_at on first save only" do
      ts = Time.now
      p = Post.new
      
      created_at = p.save.created_at
      created_at.should be_close(ts, 1)  
      
      roll_clock_forward(60) do
        created_at = p.save.created_at
        created_at.should be_close(ts, 1)  
      end
    end
    
    it "should set updated_at on each save" do
      ts = Time.now
      p = Primitives.new
      
      updated_at = p.save.updated_at
      updated_at.should be_close(ts, 1)  
      
      roll_clock_forward(60) do
        updated_at = p.save.updated_at
        updated_at.should be_close(Time.at(ts.to_i + 60), 2)  
      end      
    end
        
    it "should set created_at when first saved unless supplied to the constructor" do
      back_then = Time.now - 1000
      p = Post.new(:created_at => back_then).save
      p.created_at.should be_close(back_then, 1)
    end
    
    it "should set document conflict state on conflicting save" do      
      a1, a2 = Atom.new(:_id => "a1"), Atom.new(:_id => "a1")
      a1.save!
      a2.save
      a2.should be_update_conflict      
    end
        
  end
  
  describe "#save!" do
    
    it "should save objects" do
      a = Atom.new.save
      RelaxDB.load(a._id).should == a
    end
    
    it "should raise ValidationFailure on validation failure" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { false }
      end
      lambda do
        r.new.save!
      end.should raise_error(RelaxDB::ValidationFailure)
    end   
    
    it "should raise UpdateConflict on an update conflict" do
      a1, a2 = Atom.new(:_id => "a1"), Atom.new(:_id => "a1")
      a1.save!
      lambda { a2.save! }.should raise_error(RelaxDB::UpdateConflict)      
    end
    
  end
  
  describe "property" do
    
    it "may contain another object" do
      a = Atom.new.save!
      p = Primitives.new(:context => a).save!

      p = RelaxDB.reload p
      RelaxDB.db.reset_req_count
      p.context.to_obj.should == a
      RelaxDB.db.req_count.should == 0
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
      o.data["val"].should == 101
    end
            
  end

  describe "user defined property writer" do
    
    # So this works now, but it hasn't in the past - this behaviour has changed
    # many times. Use with caution i.e. it wouldn't be wise to rely on this
    # across a large swathe of your codebase.
    it "should only be used to modify state with caution" do
      o = BespokeWriter.new(:val => 101).save
      o = RelaxDB.load o._id
      o.val.should == 91
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
      p.false_bool.should be_false
      p.created_at.should be_close(now, 1)
      p.context.should be_nil
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
      RelaxDB.load(p._id).should be_nil
    end

    it "should prevent the object from being resaved" do
      p = Atom.new.save.destroy!
      # Exepcted failure - see http://issues.apache.org/jira/browse/COUCHDB-292      
      lambda { p.save! }.should raise_error
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
      Atom.all.should == []
    end
    
  end
  
  describe ".all.size" do
    
    it "should return the total number of docs in a single query" do
      docs = []
      100.times { docs << Atom.new }
      RelaxDB.bulk_save(*docs)
      
      RelaxDB.db.get_count = 0
      Atom.all.size.should == 100
      RelaxDB.db.get_count.should == 1
    end
    
    it "should return 0 when no docs exist" do
      Atom.all.size.should == 0
    end
    
  end
  
  describe "by_" do
      
    it "should sort ascending by default" do
      Post.new(:content => "b").save
      Post.new(:content => "a").save
      posts = Post.by_content
      posts[0].content.should == "a"
      posts[1].content.should == "b"
    end

    it "should sort desc when specified" do
      Post.new(:content => "a").save
      Post.new(:content => "b").save
      posts = Post.by_content :descending => true
      posts[0].content.should == "b"
      posts[1].content.should == "a"
    end
  
    it "should sort date attributes lexicographically" do
      t = Time.new
      Post.new(:viewed_at => t+1000, :content => "late").save
      Post.new(:viewed_at => t, :content => "early").save
      posts = Post.by_viewed_at
      posts[0].content.should == "early"
      posts[1].content.should == "late"
    end
    
    it "should return the count when queried with reduce=true" do
      docs = []
      100.times { |i| docs << Primitives.new(:num => i) }
      RelaxDB.bulk_save(*docs)
      # Create the view
      Primitives.by_num
      count = RelaxDB.view "Primitives_by_num", :reduce => true
      count.should == 100
    end
    
    describe "results" do
      
      it "should be an empty array when no docs match" do
        Post.by_subject.should == []
      end

      it "should be retrievable by exact criteria" do
        Post.new(:subject => "foo").save
        Post.new(:subject => "foo").save
        Post.new(:subject => "bar").save
        Post.by_subject(:key => "foo").size.should == 2
      end

      it "should be retrievable by relative criteria" do
        Rating.new(:stars => 1).save
        Rating.new(:stars => 5).save
        Rating.by_stars(:endkey => 3).size.should == 1
      end

      it "should be retrievable by combined criteria" do
        User.new(:name => "paul", :age => 28).save
        User.new(:name => "paul", :age => 72).save
        User.new(:name => "atlas", :age => 99).save
        User.by_name_and_age(:startkey => ["paul",0 ], :endkey => ["paul", 50]).size.should == 1
      end

      it "should be retrievable by combined criteria where not all docs contain all attributes" do
        User.new(:name => "paul", :age => 28).save
        User.new(:name => "paul", :age => 72).save
        User.new(:name => "atlas").save
        User.by_name_and_age(:startkey => ["paul",0 ], :endkey => ["paul", 50]).size.should == 1
      end
      
      it "should be retrievable by a multi key post" do
        5.times { |i| Primitives.new(:num => i).save }
        ps = Primitives.by_num :keys => [0, 4]
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
        property :thumbs_up, :validator => lambda { raise }
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

    it "should pass the property value and object to the validator" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { |tu, o| tu >=0 && o.thumbs_up < 3 }
      end
      r.new(:thumbs_up => 2).save.should be
      r.new(:thumbs_up => 3).save.should be_false
    end
    
    it "should perform all validations" do
      r = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { raise }, :validation_msg => "oof"
        property :bar, :validator => lambda { raise }, :validation_msg => "rab"
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
    
    it "should add a default error message if none is specified" do
      r = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { raise }
      end
      x = r.new
      x.save
      x.errors[:foo].should_not be_blank
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
        def count_em(tu)
          tu >=0 && tu < 3
        end
      end
      r.new(:thumbs_up => 1).save.should be
    end
    
    it "may be skipped by passing the property symbol to save" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { raise }
      end
      x = r.new
      x.validation_skip_list << :thumbs_up
      x.save!
    end
    
  end
  
  describe "validation message" do
  
    it "should be set on failure" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { false }, :validation_msg => "Too many thumbs"
      end
      x = r.new
      x.save
      x.errors[:thumbs_up].should == "Too many thumbs"
    end
    
    it "may be a proc accepting the prop only" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { false }, 
          :validation_msg => lambda { |tu| "#{tu}" }
      end      
      x = r.new(:thumbs_up => 13)
      x.save
      x.errors[:thumbs_up].should == "13"
    end
    
    
    it "may be a proc accepting the prop and object" do
      r = Class.new(RelaxDB::Document) do
        property :thumbs_up, :validator => lambda { false }, 
          :validation_msg => lambda { |tu, o| "#{tu} #{o.thumbs_up}" }
      end      
      x = r.new(:thumbs_up => 13)
      x.save
      x.errors[:thumbs_up].should == "13 13"
    end
    
  end
  
  describe "predefined validator" do
    
    it "should be invoked when a symbol clash exists" do
      c = Class.new(RelaxDB::Document) do
        property :foo, :validator => :required
        def required; raise; end;
      end
      c.new(:foo => :bar).save!.should be
    end
    
    it "should prevent an object from being saved if validation fails" do
      c = Class.new(RelaxDB::Document) do
        property :foo, :validator => :required
      end
      c.new.save.should be_false
    end    
    
  end
  
  describe "initialization process" do
    
    it "should not modify internal state unexpectedly" do
      a = Atom.new
      c = Contrived.new :context => a
      c.context_count.should == 1
      c.foo.should == 10
    end
    
  end
  
end