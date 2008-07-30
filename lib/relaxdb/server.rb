module RelaxDB

  class Server
        
    def initialize(host, port)
      @host = host
      @port = port
    end

    def delete(uri)
      request(Net::HTTP::Delete.new(uri))
    end

    def get(uri)
      request(Net::HTTP::Get.new(uri))
    end

    def put(uri, json)
      req = Net::HTTP::Put.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def post(uri, json)
      req = Net::HTTP::Post.new(uri)
      req["content-type"] = "application/json"
      req.body = json
      request(req)
    end

    def request(req)
      res = Net::HTTP.start(@host, @port) {|http|
        http.request(req)
      }
      if (not res.kind_of?(Net::HTTPSuccess))
        handle_error(req, res)
      end
      res
    end
    
    private

    def handle_error(req, res)
      e = RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
      raise e
    end
  end
  
  # Neither database name nor resource may start with a / character
  class Database
            
    def initialize(host, port, db_name, log_dev=Tempfile.new('couchdb.log'), log_level=Logger::INFO)
      @host = host
      @port = port
      @db_name = db_name
      @server = RelaxDB::Server.new(host, port)
      @logger = Logger.new(log_dev)
      @logger.level = log_level
    end
    
    def delete(uri=nil)
      @server.delete("/#{@db_name}/#{uri}")
    end
    
    def get(uri=nil)
      @server.get("/#{@db_name}/#{uri}")
    end
    
    def put(uri=nil, json=nil)
      @logger.info("PUT /#{@db_name}/#{uri} #{json}")
      @server.put("/#{@db_name}/#{uri}", json)
    end
    
    def post(uri=nil, json=nil)
      @logger.info("POST /#{@db_name}/#{uri} #{json}")
      @server.post("/#{@db_name}/#{uri}", json)
    end
    
    # Consider replacing with cattr_accessor via extlib once stable
    def self.std_db
      @@std_db
    end
    
    def self.std_db=(db)
      @@std_db = db
    end
    
    # Not convinced about setting log levels here - alternatives probably required - wait and see
    def self.set_std_db(config)
      @@std_db = RelaxDB::Database.new(config[:host], config[:port], config[:db], config[:log_dev], config[:log_level])  
    end

  end
  
  def self.use_scratch
    RelaxDB::Database.set_std_db(:host => "localhost", :port => 5984, :db => "scratch", 
      :log_dev => STDOUT, :log_level => Logger::INFO) 
  end
  
  # Yet another convenience - should probably be consolidated with others
  # Very useful for playing with views and query params from irb
  def self.get(uri)
    resp = RelaxDB::Database.std_db.get(uri)
    pp(JSON.parse(resp.body))
  end
      
end
