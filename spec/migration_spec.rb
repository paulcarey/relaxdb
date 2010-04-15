require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), "spec_models")

describe RelaxDB::Migration do
          
  before(:each) do
    @mig = RelaxDB::Migration
    setup_test_db
  end
      
  it "should yield each obj to the block and save the result" do
    Primitives.new(:num => 5).save!
    r = @mig.run Primitives do |p|
      p.num *= 2
      p
    end
    Primitives.by_num.map { |p| p.num }.should == [10]
  end
    
  it "should raise an exception if a save results in a conflict" do
    op = Primitives.new.save!
    lambda do 
      @mig.run Primitives do |p|
        op.save!
        p
      end
    end.should raise_error(RelaxDB::UpdateConflict)
  end
  
  it "should not save docs for blocks that return nil" do
    Primitives.new.save!
    @mig.run Primitives do |p| 
      nil
    end
  end
      
  describe "multiple docs" do
  
    before(:each) do
      ps = (1..5).map { |i| Primitives.new :num => i }
      RelaxDB.bulk_save *ps
      RelaxDB.db.reset_req_count
    end
    
    # Note: three requests per migration loop, plus one for the final loop
    # where no migration actually occurs. (It would be two for the final
    # loop except a request isn't isn't the id array passed to load is empty)
    it "should operate on a doc set of the given size aka limit" do
      @mig.run(Primitives, 1) { |p| p.num *= p.num; p }
      RelaxDB.db.req_count.should == 5 * 3 + 1
      Primitives.by_num.map { |p| p.num }.should == [1, 4, 9, 16, 25]      
    end

    it "should operate on a doc set of default size" do
      @mig.run(Primitives) { |p| p.num *= p.num; p }
      RelaxDB.db.req_count.should == 1 * 3 + 1
      Primitives.by_num.map { |p| p.num }.should == [1, 4, 9, 16, 25]      
    end
  
  end

  describe "#fv" do
    it "should return valid numbers" do
      @mig.fv("foo/bar/001_foo.rb").should == 1 
    end
  end
  
  describe ".run_all" do
    
    it "should save the version after each successful migration" do
      @mig.run_all ["a/b/1_"], lambda { |o| }
      RelaxDB::MigrationVersion.version.should == 1
    end

    it "should not run those migrations whose version is less than the current version" do
      v = RelaxDB::MigrationVersion.retrieve
      v.version = 2
      v.save!
      @mig.run_all ["3_"], lambda { |o| }
      RelaxDB::MigrationVersion.version.should == 3
    end
    
    it "should run those migrations whose version is greater than the current version" do
      v = RelaxDB::MigrationVersion.retrieve
      v.version = 2
      v.save!
      @mig.run_all ["1_foo"], lambda { |o| }
      RelaxDB::MigrationVersion.version.should == 2
    end
    
    it "should raise an exception on failure" do
      lambda do
        @mig.run_all ["1_foo"], lambda { |o| raise "Expected" }
      end.should raise_error(RuntimeError, "Expected")
    end
    
  end
  
end
