require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "RelaxDB Pagination" do
    
  before(:each) do
    setup_test_db    
    
    letters = [ 
      ["a", 1], ["a", 2], ["a", 3],
      ["b", 1], ["b", 2], ["b", 3], ["b", 4], ["b", 5], 
      ["c", 1], ["c", 2] 
    ].map { |o| Letter.new :letter => o[0], :number => o[1], :_id => "#{o[0]}#{o[1]}" }

    RelaxDB.bulk_save *letters        
  end

  # helper function
  def s(letters)
    letters.map { |l| "#{l.letter}#{l.number}"}.join(", ")
  end
  
  def n(letters)
    letters.map { |l| "#{l.number}"}.join(", ")
  end
    
  describe "functional tests" do

    it "should navigate through a series" do
      query = lambda do |page_params|
        RelaxDB.qpaginate_view "Letter_by_letter_and_number", :page_params => page_params,
           :startkey => ["a"], :endkey => ["a",{}], :limit => 2,
           :attributes => [:letter, :number]
      end
    
      letters = query.call({})
      s(letters).should == "a1, a2"
      letters.prev_params.should be_false
          
      letters = query.call(letters.next_params)
      s(letters).should == "a3"
      letters.next_params.should be_false
          
      letters = query.call(letters.prev_params)
      s(letters).should == "a1, a2"
      letters.next_params.should be    
    end
    
  end
    
end
