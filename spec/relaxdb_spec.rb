require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:each) do
    setup_test_db
  end
        
  describe ".create_object" do
    
    it "should return an instance of a known object if passed a hash with a class key" do
      data = { "relaxdb_class" => "Item", "_rev" => "" }
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
    
    it "should save non conflicting docs and mark conflicting docs" do
      p1, p2 = Atom.new.save!, Atom.new.save!
      Atom.new(:_id => p1._id, :_rev => p1._rev).save!
      RelaxDB.bulk_save p1, p2
      p1._rev.should =~ /1-/
      p1.should be_update_conflict
      p2._rev.should =~ /2-/
    end
    
    #
    # This spec is as much a verification of my understanding of
    # bulk_save semantics as it is a test of RelaxDB
    #
    # See http://mail-archives.apache.org/mod_mbox/couchdb-dev/200905.mbox/%3CF476A3D8-8F50-40A0-8668-C00D72196FBA@apache.org%3E
    # for an explanation of the final section 
    #
    describe "all-or-nothing" do
      it "should save non conflicting and conflicting docs" do
        p1, p2 = Primitives.new(:num => 1).save!, Primitives.new(:num => 2).save!
        p1d = Primitives.new("_id" => p1._id, "_rev" => p1._rev, "relaxdb_class" => "Primitives")
        p1d.num = 11
        p1d.save!
        p1.num = 6
        RelaxDB.bulk_save :all_or_nothing, p1, p2
        p1._rev.should =~ /2-/
        p2._rev.should =~ /2-/
        
        p1 = RelaxDB.load p1._id, :conflicts => true
        p1n1 = p1.num
        p1 = RelaxDB.load p1._id, :rev => p1._conflicts[0]
        p1n2 = p1.num
        if p1n1 == 11
          p1n2.should == 6
        else
          p1n1.should == 6 && p1n2.should == 11
        end
      end
      
      #
      # Test behind 
      # http://mail-archives.apache.org/mod_mbox/couchdb-dev/200905.mbox/%3CF476A3D8-8F50-40A0-8668-C00D72196FBA@apache.org%3E
      # Effectively defunct
      # 
      # it "non-deterministic winner" do
      #   p = Primitives.new(:num => 1).save!
      #   pd = p.dup
      #   p.num = 2
      #   p.save!
      #   pd.num = 3
      #   RelaxDB.bulk_save :all_or_nothing, pd
      #   RelaxDB.reload(p).num.should == 2
      # end
    end
        
  end
  
  describe ".bulk_save!" do
    
    it "should succeed when passed no args" do
      RelaxDB.bulk_save!
    end
    
    it "should raise when passed a nil value" do
      lambda do
        RelaxDB.bulk_save! *[nil]
      end.should raise_error
    end
    
    it "should raise an exception if a obj fails validation" do
      c = Class.new(RelaxDB::Document) do
        property :foo, :validator => lambda { false }
      end
      lambda { RelaxDB.bulk_save!(c.new) }.should raise_error(RelaxDB::ValidationFailure)
    end
    
    it "should raise an exception on document conflict after all docs have been processed" do
      p1, p2 = Atom.new.save!, Atom.new.save!
      Atom.new(:_id => p1._id, :_rev => p1._rev).save!
      lambda { RelaxDB.bulk_save!(p1, p2) }.should raise_error(RelaxDB::UpdateConflict)
      p2._rev.should =~ /2-/
    end
    
  end
  
  describe ".db_info" do
    it "should return db info" do
      RelaxDB.db_info.doc_count.should == 1
    end
  end
  
  describe ".replicate_db" do
    
    it "should replicate the named database" do
      orig = "relaxdb_spec"
      replica = "relaxdb_spec_replicate_test"
      RelaxDB.delete_db replica rescue :ok
      
      RelaxDB.enable_view_creation
      class ::ReplicaTest < RelaxDB::Document; end
      RelaxDB::View.design_doc.save
      
      ReplicaTest.new.save # implicitly saved to orig
      RelaxDB.replicate_db orig, replica
      RelaxDB.use_db replica
      ReplicaTest.all.size.should == 1      
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
    
    it "should load multiple documents in order" do
      ns = (0...100).map { rand(1_000_000_000).to_s }
      objs = ns.map { |n| Primitives.new :_id => n }
      RelaxDB.bulk_save! *objs
      ns = ns.reverse
      objs = RelaxDB.load! ns
      99.downto(0) do |i|
        ns[i].should == objs[i]._id
      end
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
      data.should == []
    end

    it "may accept query params" do
      RelaxDB::DesignDocument.get(RelaxDB.dd).add_view("simple", "map", map_func).save
      RelaxDB.db.put("x", {}.to_json)      
      RelaxDB.db.put("y", {}.to_json)      
      res = RelaxDB.view "simple", :key => "x"
      res.first._id.should == "x"
    end
    
    it "should leave relaxdb_class param intact" do
      RelaxDB::DesignDocument.get(RelaxDB.dd).add_view("simple", "map", map_func).save
      a = Atom.new.save!
      la = RelaxDB.view("simple").first
      la.should == a
      la.save!
      RelaxDB.load! la._id
    end
    
    it "should be queryable with a multi key post" do
      Primitives.view_docs_by :num
      
      5.times { |i| Primitives.new(:num => i).save }
      Primitives.by_num
      result = RelaxDB.view "Primitives_by_num", :keys => [0, 4], :reduce => false
      result.map{ |p| p.num }.should == [0, 4]
    end
    
    it "should return nil for a reduce view with no results" do
      Primitives.view_docs_by :num
      RelaxDB.view("Primitives_by_num", :reduce => true).should be_nil
    end

    it "should return a single value for a reduce view with a single result" do
      Primitives.view_docs_by :num
      Primitives.new(:num => :x).save!
      RelaxDB.view("Primitives_by_num", :reduce => true).should == 1
    end

    it "should return an array for a reduce view with multiple results" do
      Primitives.view_docs_by :num
      2.times { |i| Primitives.new(:num => i).save! }
      res = RelaxDB.view("Primitives_by_num", :reduce => true, :group => true)
      res.should be_an_instance_of(Array)
      res.size.should == 2
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
  
  describe "create_views disabled" do

    before(:each) do
      create_test_db 
      RelaxDB.enable_view_creation false
    
      class CvdBar < RelaxDB::Document
        view_docs_by :foo
      end
    end

    it "should not create any views" do
      dd = RelaxDB::DesignDocument.get "spec_doc"
      dd.data["views"].should be_nil
    end    

  end
  
  describe "create_views enabled" do

    before(:each) do
      create_test_db

      RelaxDB.enable_view_creation
      
      class ::CveBar < RelaxDB::Document
        view_docs_by :foo
      end
      
      RelaxDB::View.design_doc.save
    end

    it "should create all views" do
      dd = RelaxDB::DesignDocument.get "spec_doc"
      dd.data["views"]["CveBar_all"].should be
      dd.data["views"]["CveBar_by_foo"].should be
    end    

  end
  
  # if caching is added
  # it "should offer an example where behaviour is different with caching enabled and caching disabled"
            
end
