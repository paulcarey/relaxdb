require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end
        
  describe ".create_object" do
    
    it "should return an instance of a known object if passed a hash with a class key" do
      data = { "class" => "Item" }
      obj = RelaxDB.create_object(data)
      obj.should be_instance_of(Item)
    end
    
    it "should return an instance of a dynamically created object if no class key is provided" do
      data = { "name" => "tesla coil", "strength" => 5000 }
      obj = RelaxDB.create_object(data)
      obj.name.should == "tesla coil"
      obj.strength.should == 5000
    end
    
  end  

  # bulk_save and bulk_save! should match Document#save and Document#save! semantics
  describe ".bulk_save" do
    
    it "should be invokable multiple times" do
      t1, t2 = Tag.new, Tag.new
      RelaxDB.bulk_save(t1, t2)
      RelaxDB.bulk_save(t1, t2)
    end
    
    it "should return the objects it was passed" do
      t1, t2 = Tag.new, Tag.new
      ta, tb = RelaxDB.bulk_save(t1, t2)
      ta.should == t1
      tb.should == t2
    end
    
    it "should succeed when passed no args" do
      RelaxDB.bulk_save
    end
    
    it "should return false on failure" do
      c = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { false }
      end
      x = c.new
      RelaxDB.bulk_save(x).should be_false
    end

    it "should not attempt to save if a pre-save stage fails" do
      c = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { false }
      end
      x = c.new
      RelaxDB.bulk_save(x)
      x.should be_new_document
    end
    
    it "should invoke the after-save stage after a successful save" do
      c = Class.new(RelaxDB::Document) do
        attr_accessor :foo
        after_save lambda { |c| c.foo = :bar }
      end
      x = c.new
      RelaxDB.bulk_save(x).first.foo.should == :bar
    end
    
  end
  
  describe ".bulk_save!" do
    
    it "should raise an exception if a obj fails validation" do
      c = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { false }
      end
      lambda { RelaxDB.bulk_save!(c.new) }.should raise_error(RelaxDB::ValidationFailure)
    end
    
    it "should raise an exception if a document update conflict occurs on save" do
      Atom.new(:_id => "a1").save!
      lambda { RelaxDB.bulk_save! Atom.new(:_id => "a1") }.should raise_error(RelaxDB::UpdateConflict)
    end
    
  end
  
  describe ".replicate_db" do
    
    it "should replicate the named database" do
      orig = "relaxdb_spec_db"
      replica = "relaxdb_spec_db_replica"
      RelaxDB.delete_db replica rescue "ok"
      Atom.new.save # implicitly saved to orig
      RelaxDB.replicate_db orig, replica
      RelaxDB.use_db replica
      Atom.all.size.should == 1
    end
    
  end
  
  describe ".load" do
    
    it "should load a single document" do
      a = Atom.new.save
      ar = RelaxDB.load a._id
      ar.should == a
    end
    
    it "should load an arbitrary number of documents" do
      a1, a2 = Atom.new.save, Atom.new.save
      ar1, ar2 = RelaxDB.load [a1._id, a2._id]
      ar1.should == a1
      ar2.should == a2
    end
    
    it "should return nil when given a id for a non existant doc" do
      RelaxDB.load("nothere").should be_nil
    end
    
    it "should return an array with correctly placed nils when given a list containing non existant doc ids" do
      a1, a2 = Atom.new.save, Atom.new.save
      res = RelaxDB.load [nil, a1._id, nil, a2._id, nil]
      res.should == [nil, a1, nil, a2, nil]
    end
    
  end
  
  describe ".load!" do
    
    it "should load a single document" do
      a = Atom.new.save
      ar = RelaxDB.load! a._id
      ar.should == a      
    end
    
    it "should load multiple documents" do
      a1, a2 = Atom.new.save, Atom.new.save
      ar1, ar2 = RelaxDB.load! [a1._id, a2._id]
      ar1.should == a1
      ar2.should == a2
    end
    
    it "should throw an exception if given a single id for a non-existant doc" do
      lambda do
        RelaxDB.load! "nothere"
      end.should raise_error(RelaxDB::NotFound)
    end
    
    it "should throw an exception if any of a list of doc ids is for a non-existant doc" do
      a = Atom.new.save
      lambda do
        RelaxDB.load! [nil, a._id]
      end.should raise_error(RelaxDB::NotFound)
    end
    
  end
  
  describe ".view" do
    
    map_func = %Q<
      function (doc) {
        emit(doc._id, doc);
      }
    >
    
    it "should request a view and return an array" do
      RelaxDB::DesignDocument.get(RelaxDB.dd).add_view("simple", "map", map_func).save
      data = RelaxDB.view("simple")
      data.should be_instance_of(Array)
    end

    it "may accept query params" do
      RelaxDB::DesignDocument.get(RelaxDB.dd).add_view("simple", "map", map_func).save
      RelaxDB.db.put("x", {}.to_json)      
      RelaxDB.db.put("y", {}.to_json)      
      res = RelaxDB.view "simple", :key => "x"
      res.first._id.should == "x"
    end
    
    it "should be queryable with a multi key post" do
      5.times { |i| Primitives.new(:num => i).save }
      Primitives.all.sorted_by(:num) 
      result = RelaxDB.view "Primitives_by_num", :keys => [0, 4], :reduce => false
      result.map{ |p| p.num }.should == [0, 4]
    end
    
  end
  
  describe ".merge" do
    
    it "should merge rows sharing a common merge key into a single ViewObject" do
      rows = [
        {"value" => {"sculptor_id" => 1, "sculpture_name" => "strandbeesten"} },
        {"value" => {"sculptor_id" => 1, "sculptor_name" => "hans"} },
        {"value" => {"sculptor_id" => 2, "sculpture_name" => "parading dogs"} },
        {"value" => {"sculptor_id" => 2, "sculptor_name" => "holmes"} }
      ]
      data = {"rows" => rows}
      result = RelaxDB.merge(data, "sculptor_id")
      result = result.sort { |a, b| a.sculptor_name <=> b.sculptor_name }      

      result[0].sculptor_name.should == "hans"
      result[0].sculpture_name.should == "strandbeesten"
      result[1].sculptor_name.should == "holmes"
      result[1].sculpture_name.should == "parading dogs"
    end
        
  end
  
  # if caching is added
  # it "should offer an example where behaviour is different with caching enabled and caching disabled"
            
end
