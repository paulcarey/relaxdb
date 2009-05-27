require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), "spec_models")

describe RelaxDB::MigrationVersion do
  
  before(:each) do
    setup_test_db
  end
  
  it "should not exist in a clean db" do
    RelaxDB.load(RelaxDB::MigrationVersion::DOC_ID).should be_nil
  end
  
  it "should return zero when it doesnt exist" do
    RelaxDB::MigrationVersion.version.should == 0
  end
  
  it "should autosave on retrieval when when it doesnt exist" do
    RelaxDB::MigrationVersion.version
    RelaxDB.load(RelaxDB::MigrationVersion::DOC_ID).should be
  end
  
  it "should return the saved version" do
    RelaxDB::MigrationVersion.update 10
    RelaxDB::MigrationVersion.version.should == 10
  end
  
end
