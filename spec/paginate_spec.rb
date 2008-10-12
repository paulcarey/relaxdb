require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe "RelaxDB Pagination" do
    
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
    
    Letter.new(:letter => "a", :number => 1).save
    Letter.new(:letter => "a", :number => 2).save
    Letter.new(:letter => "a", :number => 3).save
    Letter.new(:letter => "b", :number => 1).save
    Letter.new(:letter => "b", :number => 2).save
    Letter.new(:letter => "b", :number => 3).save
    Letter.new(:letter => "b", :number => 4).save
    Letter.new(:letter => "b", :number => 5).save
    Letter.new(:letter => "c", :number => 1).save
    Letter.new(:letter => "c", :number => 2).save    
  end

  # helper function
  def s(letters)
    letters.map { |l| "#{l.letter}#{l.number}"}.join(", ")
  end
    
  describe "functional tests" do

    it "should navigate through a series" do
      page_params = {}
      query = lambda do
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["a"]).endkey(["a",{}]).count(2)
        end
      end
    
      letters = query.call
      s(letters).should == "a1, a2"
      letters.prev_params.should be_false
      page_params = letters.next_params
    
      letters = query.call
      s(letters).should == "a3"
      letters.next_params.should be_false
      page_params = letters.prev_params
    
      letters = query.call
      s(letters).should == "a1, a2"
      letters.prev_params.should be_false
      letters.next_params.should be    
    end

    it "should navigate through b series with descending false" do
      page_params = {}
      query = lambda do
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["b"]).endkey(["b",{}]).count(2)
        end
      end
    
      letters = query.call
      s(letters).should == "b1, b2"
      letters.prev_params.should be_false
      page_params = letters.next_params
      
      letters = query.call
      s(letters).should == "b3, b4"
      letters.next_params.should be
      page_params = letters.prev_params

      letters = query.call
      s(letters).should == "b1, b2"
      letters.prev_params.should be_false
      page_params = letters.next_params
    
      letters = query.call
      s(letters).should == "b3, b4"
      letters.prev_params.should be
      page_params = letters.next_params
    
      letters = query.call
      s(letters).should == "b5"
      letters.next_params.should be_false
      page_params = letters.prev_params

      letters = query.call
      s(letters).should == "b3, b4"
      letters.next_params.should be
      page_params = letters.prev_params
    
      letters = query.call
      s(letters).should == "b1, b2"
      letters.prev_params.should be_false
      letters.next_params.should be
    end

    it "should navigate through b series with descending true" do
      page_params = {}
      query = lambda do
         Letter.paginate_by(page_params, :letter, :number) do |p|
           p.startkey(["b", {}]).endkey(["b"]).descending(true).count(2)
        end
      end
    
      letters = query.call
      s(letters).should == "b5, b4"
      letters.prev_params.should be_false
      page_params = letters.next_params
    
      letters = query.call
      s(letters).should == "b3, b2"
      letters.prev_params.should be
      page_params = letters.next_params
    
      letters = query.call
      s(letters).should == "b1"
      letters.next_params.should be_false
      page_params = letters.prev_params

      letters = query.call
      s(letters).should == "b3, b2"
      letters.next_params.should be
      page_params = letters.prev_params
    
      letters = query.call
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
  
  describe "simple (non array) keys" do
    
    it "should work"
    
  end
    
end
