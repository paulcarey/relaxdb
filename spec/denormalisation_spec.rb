require File.dirname(__FILE__) + '/spec_helper.rb'

# Experimental only for now

class Tree < RelaxDB::Document
  property :name
  property :climate
  has_one :leaf
end

class Leaf < RelaxDB::Document
  belongs_to :tree, :denormalise => [:name]
end

describe RelaxDB::Document, "denormalisation" do

  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end

  describe "belongs_to" do
        
    it "should store denormalised options in its json representation" do
      tree = Tree.new(:name => "sapling").save
      leaf = Leaf.new(:tree => tree)
      obj = JSON.parse(leaf.to_json)
      obj["tree_name"].should == "sapling"
    end
    
    it "should not interfere with normal belongs_to behaviour" do
      tree = Tree.new(:name => "sapling", :climate => "tropical").save
      leaf = Leaf.new(:tree => tree).save
      leaf = RelaxDB.load(leaf._id)      
      leaf.tree.name.should == "sapling"
      leaf.tree.climate.should == "tropical"
    end
    
  end
  
end
