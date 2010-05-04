require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::UuidGenerator do
    
  before(:all) do
    setup_test_db
    @ug = RelaxDB::UuidGenerator
  end
  
  before(:each) do
    @ug.reset
  end
    
  it "should retrieve UUIDs from CouchDB" do
    RelaxDB.db.reset_req_count
    @ug.uuid
    RelaxDB.db.get_count.should == 1
  end
  
  it "should retrieve count number of UUIDs" do
    RelaxDB.db.reset_req_count
    @ug.count = 1
    3.times { @ug.uuid }
    RelaxDB.db.get_count.should == 3
  end
  
  it "should retrieve n UUIDs from CouchDB in a single request" do
    RelaxDB.db.reset_req_count
    100.times { @ug.uuid }
    RelaxDB.db.get_count.should == 1
  end
  
end
