require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"
    @server = RelaxDB::Server.new("localhost", 5984)
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec" rescue "ok"
    RelaxDB.use_db "relaxdb_spec"    
  end
        
  describe "GET" do
    
    it "should raise a HTTP_404 for a non existant doc" do
      lambda do
        @server.get "/relaxdb_spec/foo"
      end.should raise_error(RelaxDB::HTTP_404)
    end

    it "should raise a RuntimeError for non specific errors" do
      lambda do
        @server.get "/relaxdb_spec/_view?fail=true"
      end.should raise_error(RuntimeError)
    end
    
  end
  
end
