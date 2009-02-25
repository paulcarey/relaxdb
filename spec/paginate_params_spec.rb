require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::PaginateParams do
    
  it "should be invalid if hasn't been initialized with both a startkey and endkey" do
    RelaxDB::PaginateParams.new({}).should be_invalid
  end

  it "should be valid if initialized with both a startkey and endkey" do
    pp = RelaxDB::PaginateParams.new :startkey => nil, :endkey => nil
    pp.should_not be_invalid
  end
  
end
