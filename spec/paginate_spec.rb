require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "RelaxDB Pagination" do
    
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
    # RelaxDB.configure(:host => "localhost", :port => 5984, :logger => Logger.new(STDOUT))  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
    
    Letter.new(:letter => "a", :number => 1).save # :_id => "a1",
    Letter.new(:letter => "a", :number => 2).save # :_id => "a2", 
    Letter.new(:letter => "a", :number => 3).save # :_id => "a3", 
    Letter.new(:letter => "b", :number => 1).save # :_id => "b1", 
    Letter.new(:letter => "b", :number => 2).save # :_id => "b2", 
    Letter.new(:letter => "b", :number => 3).save # :_id => "b3", 
    Letter.new(:letter => "b", :number => 4).save # :_id => "b4", 
    Letter.new(:letter => "b", :number => 5).save # :_id => "b5", 
    Letter.new(:letter => "c", :number => 1).save # :_id => "c1", 
    Letter.new(:letter => "c", :number => 2).save # :_id => "c2",    
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
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["a"]).endkey(["a",{}]).count(2)
        end
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
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["b"]).endkey(["b",{}]).count(2)
        end
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
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["b", {}]).endkey(["b"]).descending(true).count(2)
        end
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
      letters = Letter.paginate_by({}, :letter, :number) do |p|
        p.startkey(["c"]).endkey(["c", {}]).count(2)
      end
    
      letters.next_params.should be_false
      letters.prev_params.should be_false
    end
    
  end
  
  describe "next_query" do

    it "should emit a url encoded and json encoded string with query name page_params" do
      letters = Letter.paginate_by({:startkey => ["b", 2]}, :letter, :number) do |p|
         p.startkey(["b"]).endkey(["b",{}]).count(2)
      end
      
      # unescape and parse required as param order is implementation dependent
      hash = JSON.parse(CGI.unescape(letters.next_query.split("=")[1]))
      
      hash["descending"].should be_false
      hash["startkey"].should == ["b", 4]
    end
    
    it "should be treated as next_param by the paginator" do
      page_params = {}
      query = lambda do
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["b"]).endkey(["b", {}]).count(2)
        end
      end
      
      letters = query.call      
      page_params = ::CGI::unescape(letters.next_query.split("=")[1])
      letters = query.call
      s(letters).should == "b3, b4"
    end
    
  end
  
  describe "prev_query" do
    
    it "should be treated as prev_query by the paginator" do
      page_params = {}
      query = lambda do
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["b", {}]).endkey(["b"]).descending(true).count(2)
        end
      end
      
      letters = query.call      
      page_params = ::CGI::unescape(letters.next_query.split("=")[1])
      letters = query.call
      s(letters).should == "b3, b2"
    end
    
    it "should emit a url encoded and json encoded string with query name page_params" do
      letters = Letter.paginate_by({:startkey => ["b", 2]}, :letter, :number) do |p|
         p.startkey(["b"]).endkey(["b",{}]).count(2)
      end
      
      hash = JSON.parse(CGI.unescape(letters.prev_query.split("=")[1]))
      
      hash["descending"].should be_true
      hash["startkey"].should == ["b", 3]
    end
    
  end
  
  describe "multiple keys per doc" do
    
    it "should not yet be used with pagination" do
      # use a - create map func with emitting multiple times
    end
    
  end
  
  describe "multiple keys per document, simple (non array) keys" do
    
    it "should work when descending is false" do
      query = lambda do |page_params|
        Letter.paginate_by(page_params, :number) do |p|
          p.startkey(1).endkey({}).count(4)
        end
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
        Letter.paginate_by(page_params, :number) do |p|
          p.startkey(5).endkey(nil).descending(true).count(4)
        end
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
    
    it "should not get stuck when the number of keys exceeds the count" do
      query = lambda do |page_params|
        Letter.paginate_by(page_params, :number) do |p|
          p.startkey(1).endkey({}).count(2)
        end
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
        Letter.paginate_by({}, :number) { |p| p.startkey(1).descending(true) }
      end.should raise_error
    end
    
    it "should return an empty array when no documents exist" do
      Letter.all.destroy!
      letters = Letter.paginate_by({}, :number) { |p| p.startkey(1).endkey(3) }
      letters.should be_empty
    end

    it "should return an array that responds negatively to next_query and prev_query when no documents exist" do
      Letter.all.destroy!
      letters = Letter.paginate_by({}, :number) { |p| p.startkey(1).endkey(3) }
      letters.prev_query.should be_false
      letters.next_query.should be_false
    end
    
  end
    
end
