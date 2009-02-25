require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "RelaxDB Pagination" do
    
  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"    
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
    
    class ViewBySpec < RelaxDB::Document
      property :foo
      property :bar
      view_by :foo
      view_by :foo, :bar
    end
    
  end
    
  describe "view_by" do
    
    it "should create corresponding views" do
      dd = RelaxDB::DesignDocument.get("spec_doc")
      dd.data["views"]["ViewBySpec_by_foo"].should be
    end
    
    # think production
    it "should not create the views if a given switch is on" do
      
    end    
    
    it "should create a by_ att list method" do
      vbs = ViewBySpec.new(:foo => :bar).save!
      res = ViewBySpec.by_foo
      res.first.foo.should == "bar"
    end
    
    it "should create a paginate_by_ att list method" do
      vbs = ViewBySpec.new(:foo => :bar, :bar => :foo).save!      
      res = ViewBySpec.paginate_by_foo_and_bar :page_params => {}, :startkey => nil, :endkey => {}
      res.first.foo.should == "bar"
    end
    
    it "should have pagination tested thoroughly" do
      
    end
    
    it "should apply query defaults" do
      
    end
    
    it "should allow query defaults to be overridden" do
      
    end
        
  end
  
end