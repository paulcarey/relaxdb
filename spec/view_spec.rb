require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::View do
    
  describe "exists" do
    
    before(:each) do
      create_test_db
    end
    
    it "should return nil if a view doesnt exist" do
      RelaxDB::ViewCreator.all.should_not be_exists
    end
    
    it "should return the view if it exits" do
      RelaxDB::ViewCreator.all.save
      RelaxDB::ViewCreator.all.should be_exists
    end

  end

end
