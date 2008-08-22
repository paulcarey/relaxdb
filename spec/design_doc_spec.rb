require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::DesignDocument do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984, :db => "relaxdb_spec_db")  
  end

  before(:each) do
    RelaxDB.db.delete
    RelaxDB.db.put
  end

  describe "#save" do
    
    it "should create a corresponding document in CouchDB" do
      RelaxDB::DesignDocument.get("foo").save      
      RelaxDB.load("_design/foo").should_not be_nil
    end
    
  end

  describe "#destroy" do
    
    it "should delete the corresponding document from CouchDB" do
      dd = RelaxDB::DesignDocument.get("foo").save
      dd.destroy!
      lambda { RelaxDB.load("_design/foo") }.should raise_error
    end
    
  end

end