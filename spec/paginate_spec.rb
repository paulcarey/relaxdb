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
         Letter.paginate_by_letter_and_number :page_params => page_params,
           :startkey => ["a"], :endkey => ["a",{}], :limit => 2
      end
    
      letters = query.call({})
      s(letters).should == "a1, a2"
      letters.prev_params.should be_false
    
      letters = query.call(letters.next_params)
      s(letters).should == "a3"
      letters.next_params.should be_false
    
      letters = query.call(letters.prev_params)
      s(letters).should == "a1, a2"
      letters.prev_params.should be_false
      letters.next_params.should be    
    end

    it "should navigate through b series with descending false" do
      query = lambda do |page_params|
         Letter.paginate_by_letter_and_number :page_params => page_params,
           :startkey => ["b"], :endkey => ["b",{}], :limit => 2
      end
    
      letters = query.call({})
      s(letters).should == "b1, b2"
      letters.prev_params.should be_false
      
      letters = query.call(letters.next_params)
      s(letters).should == "b3, b4"
      letters.next_params.should be

      letters = query.call(letters.prev_params)
      s(letters).should == "b1, b2"
      letters.prev_params.should be_false
    
      letters = query.call(letters.next_params)
      s(letters).should == "b3, b4"
      letters.prev_params.should be
    
      letters = query.call(letters.next_params)
      s(letters).should == "b5"
      letters.next_params.should be_false

      letters = query.call(letters.prev_params)
      s(letters).should == "b3, b4"
      letters.next_params.should be
    
      letters = query.call(letters.prev_params)
      s(letters).should == "b1, b2"
      letters.prev_params.should be_false
      letters.next_params.should be
    end

    it "should navigate through b series with descending true" do      
      query = lambda do |page_params|
         Letter.paginate_by_letter_and_number :page_params => page_params,
           :startkey => ["b", {}], :endkey => ["b"], :descending => true, :limit => 2
      end      
    
      letters = query.call({})
      s(letters).should == "b5, b4"
      letters.prev_params.should be_false
    
      letters = query.call(letters.next_params)
      s(letters).should == "b3, b2"
      letters.prev_params.should be
    
      letters = query.call(letters.next_params)
      s(letters).should == "b1"
      letters.next_params.should be_false

      letters = query.call(letters.prev_params)
      s(letters).should == "b3, b2"
      letters.next_params.should be
    
      letters = query.call(letters.prev_params)
      s(letters).should == "b5, b4"
      letters.prev_params.should be_false
      letters.next_params.should be
    end
  
    it "should not display pagination options for c series" do
      letters = Letter.paginate_by_letter_and_number :page_params => {},
        :startkey => ["c"], :endkey => ["c", {}], :limit => 2      
    
      letters.next_params.should be_false
      letters.prev_params.should be_false
    end
    
  end
  
  describe "next_query" do

    it "should emit a url encoded and json encoded string with query name page_params" do
      letters = Letter.paginate_by_letter_and_number :page_params => {:startkey => ["b", 2]},
         :startkey => ["b"], :endkey => ["b",{}],:limit => 2
      
      # unescape and parse required as param order is implementation dependent
      hash = JSON.parse(CGI.unescape(letters.next_query.split("=")[1]))
      
      hash["descending"].should be_false
      hash["startkey"].should == ["b", 4]
    end
    
    it "should be treated as next_param by the paginator" do
      page_params = {}
      query = lambda do
        Letter.paginate_by_letter_and_number :page_params => page_params,
          :startkey => ["b"], :endkey => ["b",{}], :limit => 2        
      end
      
      letters = query.call      
      page_params = CGI::unescape(letters.next_query.split("=")[1])
      letters = query.call
      s(letters).should == "b3, b4"
    end
    
  end
  
  describe "prev_query" do
    
    it "should be treated as prev_query by the paginator" do
      page_params = {}
      query = lambda do
        Letter.paginate_by_letter_and_number :page_params => page_params,
          :startkey => ["b", {}], :endkey => ["b"], :descending => true, :limit => 2
      end
      
      letters = query.call      
      page_params = CGI::unescape(letters.next_query.split("=")[1])
      letters = query.call
      s(letters).should == "b3, b2"
    end
    
    it "should emit a url encoded and json encoded string with query name page_params" do      
      letters = Letter.paginate_by_letter_and_number :page_params => {:startkey => ["b", 2]},
         :startkey => ["b"], :endkey => ["b",{}],:limit => 2
      
      hash = JSON.parse(CGI.unescape(letters.prev_query.split("=")[1]))
      
      hash["descending"].should be_true
      hash["startkey"].should == ["b", 3]
    end
    
  end
    
  describe "multiple keys per document, simple (non array) keys" do
    
    it "should work when descending is false" do
      query = lambda do |page_params|
        Letter.paginate_by_number :page_params => page_params,
          :startkey => 1, :endkey => {}, :limit => 4
      end
      
      numbers = query.call({})
      n(numbers).should == "1, 1, 1, 2"
      numbers.prev_params.should be_false
      
      numbers = query.call(numbers.next_params)
      n(numbers).should == "2, 2, 3, 3"
      numbers.next_params.should be
      
      numbers = query.call(numbers.prev_params)
      n(numbers).should == "1, 1, 1, 2"
      numbers.prev_params.should be_false
      
      numbers = query.call(numbers.next_params)
      n(numbers) == "2, 2, 3, 3"
      numbers.prev_params.should be
      
      numbers = query.call(numbers.next_params)
      n(numbers) == "4, 5"
      numbers.next_params.should be_false
      
      numbers = query.call(numbers.prev_params)
      n(numbers) == "2, 2, 3, 3"
      numbers.next_params.should be
      
      numbers = query.call(numbers.prev_params)
      n(numbers) == "1, 1, 1, 2"
      numbers.next_params.should be
      numbers.prev_params.should be_false
    end

    it "should work when descending is true" do
      query = lambda do |page_params|
        Letter.paginate_by_number :page_params => page_params,
          :startkey => 5, :endkey => nil, :descending => true, :limit => 4        
      end
      
      numbers = query.call({})
      n(numbers).should == "5, 4, 3, 3"
      numbers.prev_params.should be_false
      
      numbers = query.call(numbers.next_params)
      n(numbers).should == "2, 2, 2, 1"
      numbers.next_params.should be

      numbers = query.call(numbers.prev_params)
      n(numbers).should == "5, 4, 3, 3"
      numbers.prev_params.should be_false

      numbers = query.call(numbers.next_params)
      n(numbers).should == "2, 2, 2, 1"
      numbers.prev_params.should be

      numbers = query.call(numbers.next_params)
      n(numbers).should == "1, 1"
      numbers.next_params.should be_false

      numbers = query.call(numbers.prev_params)
      n(numbers).should == "2, 2, 2, 1"
      numbers.next_params.should be

      numbers = query.call(numbers.prev_params)
      n(numbers).should == "5, 4, 3, 3"
      numbers.prev_params.should be_false
      numbers.next_params.should be
    end
    
    it "should not get stuck when the number of keys exceeds the limit" do
      query = lambda do |page_params|
        Letter.paginate_by_number :page_params => page_params,
          :startkey => 1, :endkey => {}, :limit => 2
      end
      
      numbers = query.call({})
      n(numbers).should == "1, 1"
      numbers = query.call(numbers.next_params)
      n(numbers).should == "1, 2"
    end
    
  end
  
  describe ".paginate_by" do
    
    it "should throw an error unless both startkey and endkey are specified" do
      lambda do
        Letter.paginate_by_number :page_params => page_params, :startkey => 1, :limit => 2
      end.should raise_error
    end
    
    it "should return an empty array when no documents exist" do
      Letter.all.destroy!
      letters = Letter.paginate_by_number :page_params => {}, :startkey => 1, :endkey => 3
      letters.should be_empty
    end

    it "should return an array that responds negatively to next_query and prev_query when no documents exist" do
      Letter.all.destroy!
      letters = Letter.paginate_by_number :page_params => {}, :startkey => 1, :endkey => 3
      letters.prev_query.should be_false
      letters.next_query.should be_false
    end
    
  end
  
  describe ".paginate_view functional tests" do
    
    def navigate_b_series(query)
      letters = query.call({})
      s(letters).should == "b1, b2"
      letters.prev_params.should be_false
      
      letters = query.call(letters.next_params)
      s(letters).should == "b3, b4"
      letters.prev_params.should be
      
      letters = query.call(letters.next_params)
      s(letters).should == "b5"
      letters.next_params.should be_false
      
      letters = query.call(letters.prev_params)
      s(letters).should == "b3, b4"
      letters.next_params.should be
      
      letters = query.call(letters.prev_params)
      s(letters).should == "b1, b2"
      letters.next_params.should be
      letters.prev_params.should be_false      
    end
    
    before(:each) do
      map = <<-FUNC
        function (doc) {
          if (doc.relaxdb_class === "Letter") {
            emit([doc.letter, doc.number], doc);
          }
        }
      FUNC
      
      reduce = <<-FUNC
        function (keys, values, combine) {
          return values.length;
        }
      FUNC
      
      view_name = "Letter_by_letter_and_number"
      RelaxDB::DesignDocument.get(RelaxDB.dd).add_map_view(view_name, map).add_reduce_view(view_name, reduce).save      
    end
    
    it "should pass using symbols as view_keys" do
      query = lambda do |page_params|
        RelaxDB.paginate_view "Letter_by_letter_and_number", :page_params => page_params,
          :startkey => ["b"], :endkey => ["b", {}], :limit => 2, :attributes => [:letter, :number]
      end
      navigate_b_series query
    end

    it "should pass using symbols and values as view_keys" do
      query = lambda do |page_params|
        RelaxDB.paginate_view "Letter_by_letter_and_number", :page_params => page_params,
          :startkey => ["b"], :endkey => ["b", {}], :limit => 2, :attributes => ["b", :number]
      end
      navigate_b_series query
    end
    
    it "should pass using lambdas as view_keys" do
      query = lambda do |page_params|
        RelaxDB.paginate_view "Letter_by_letter_and_number", :page_params => page_params,
          :startkey => ["b"], :endkey => ["b", {}], :limit => 2, 
          :attributes => ["b", lambda { |l| l.number } ]
      end
      navigate_b_series query
    end    
    
  end
    
end
