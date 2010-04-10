require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "view_docs_by" do
    
  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"    
  end
    
  describe "view_docs_by" do
    
    before(:each) do
      RelaxDB.delete_db "relaxdb_spec" rescue "ok"
      RelaxDB.use_db "relaxdb_spec"
      RelaxDB.enable_view_creation

      class ::ViewByFoo < RelaxDB::Document
        property :foo
        view_docs_by :foo, :descending => true
      end
      
      RelaxDB::View.design_doc.save
      
    end
    
    it "should create corresponding views" do
      dd = RelaxDB::DesignDocument.get "spec_doc"
      dd.data["views"]["ViewByFoo_by_foo"].should be
    end
      
    it "should create a by_ att list method" do
      ViewByFoo.new(:foo => :bar).save!
      res = ViewByFoo.by_foo
      res.first.foo.should == "bar"
    end
        
    it "should create a paginate_by_ att list method" do
      ViewByFoo.new(:foo => :bar).save!      
      res = ViewByFoo.paginate_by_foo :page_params => {}, :startkey => {}, :endkey => nil
      res.first.foo.should == "bar"
    end
        
    it "should apply query defaults to by_" do
      ViewByFoo.new(:foo => "a").save!
      ViewByFoo.new(:foo => "b").save!
      
      ViewByFoo.by_foo.map{ |o| o.foo }.should == ["b", "a"]
    end
    
    it "should return the right count size" do
      docs = (1..101).map { |i| ViewByFoo.new :foo => i }
      RelaxDB.bulk_save! *docs
      count = RelaxDB.view "ViewByFoo_by_foo", :reduce => true
      count.should == 101
    end
    
    it "should allow a single arg to be passed to by_" do
      vbf = ViewByFoo.new(:foo => "a").save!
      ViewByFoo.by_foo("a").should == vbf
    end
    
    it "should apply query defaults to paginate_by_" do
      ViewByFoo.new(:foo => "a").save!
      ViewByFoo.new(:foo => "b").save!
      
      res = ViewByFoo.paginate_by_foo :page_params => {}, :startkey => {}, :endkey => nil
      res.map{ |o| o.foo }.should == ["b", "a"]
    end
    
    it "should allow query defaults to be overridden for paginate_by_" do
      ViewByFoo.new(:foo => :bar).save!      
      res = ViewByFoo.paginate_by_foo :page_params => {}, :startkey => nil, :endkey => {}, :descending => false
      res.first.foo.should == "bar"      
    end
    
    it "should allow query defaults to be overridden for by_" do
      ViewByFoo.new(:foo => "a").save!
      ViewByFoo.new(:foo => "b").save!
      
      ViewByFoo.by_foo(:descending => false).map{ |o| o.foo }.should == ["a", "b"]
    end
        
  end
    
end