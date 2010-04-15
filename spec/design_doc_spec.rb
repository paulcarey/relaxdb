require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::DesignDocument do
  
  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec" rescue "ok"
    RelaxDB.use_db "relaxdb_spec"
  end

  describe "#save" do
    
    it "should create a corresponding document in CouchDB" do
      RelaxDB::DesignDocument.get("foo").save
      RelaxDB::DesignDocument.get("foo").should_not be_nil
    end
    
  end

  describe "#destroy" do
    
    it "should delete the corresponding document from CouchDB" do
      dd = RelaxDB::DesignDocument.get("foo").save
      dd.destroy!
      RelaxDB.load("_design/foo").should be_nil
    end
    
  end

end