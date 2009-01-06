require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

# These tests would ideally instrument server.rb, asserting that no
# HTTP requests are made when retrieving the derived values

class DpInvite < RelaxDB::Document
  property :event_name, :derived => [:event, lambda { |en, i| i.event.name }]
  belongs_to :event  
end

class DpEvent < RelaxDB::Document
  property :name  
end

describe RelaxDB::Document, "derived properties" do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end
  
  it "should have its value updated when the source is updated" do
    e = DpEvent.new(:name => "shindig")
    i = DpInvite.new(:event => e)
    i.event_name.should == "shindig"
  end
  
  it "should have its value persisted" do
    e = DpEvent.new(:name => "shindig").save!
    i = DpInvite.new(:event => e).save!
    
    RelaxDB.db.get_count = 0
    i = RelaxDB.load i._id
    i.event_name.should == "shindig"
    RelaxDB.db.get_count.should == 1
  end  
  
  it "should have its value updated when the source_id is updated for a saved event" do
    e = DpEvent.new(:name => "shindig").save!
    i = DpInvite.new(:event_id => e._id)
    i.event_name.should == "shindig"
  end  
  
  it "will fail when the source_id is updated for a unsaved event" do
    # Almost certainly not desired - merely codifying current behaviour
    e = DpEvent.new(:name => "shindig")
    lambda { DpInvite.new(:event_id => e._id) }.should raise_error
  end  
  
  it "should only be updated for registered properties" do
    invite = Class.new(RelaxDB::Document) do
      property :event_name, :derived => [:foo, lambda { |en, i| i.event.name }]
      belongs_to :event
    end
    
    event = Class.new(RelaxDB::Document) do
      property :name
    end
    
    e = event.new(:name => "shindig")
    i = invite.new(:event => e)
    i.event_name.should be_nil
  end
  
  it "should have the existing value passed to the first lambda param" do
    invite = Class.new(RelaxDB::Document) do
      property :event_name, :derived => [:event, lambda { |en, i| en.nil? ? i.event.name : "bar" }]
      belongs_to :event
    end
    
    event = Class.new(RelaxDB::Document) do
      property :name
    end
    
    e1 = event.new(:name => "shindig")
    e2 = event.new(:name => "shindig2")
    i = invite.new(:event => e1)
    i.event = e2
    i.event_name.should == "bar"
  end
  
  describe "multiple properties" do

    it "should be derivable from the same source" do
      invite = Class.new(RelaxDB::Document) do
        property :name, :derived => [:event, lambda { |en, i| i.event.name }]
        property :location, :derived => [:event, lambda { |en, i| i.event.location }]
        belongs_to :event
      end

      event = Class.new(RelaxDB::Document) do
        property :name
        property :location
      end

      e = event.new(:name => "shindig", :location => "city17")
      i = invite.new(:event => e)
      i.name.should == "shindig"
      i.location.should == "city17"
    end     
    
  end
  
end
