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
            
    def initialize(host, port, db_name)
      @host = host
      @port = port
      @db_name = db_name
      @server = RelaxDB::Server.new(host, port)
    end
    
    def delete(uri=nil)
      @server.delete("/#{@db_name}")
    end
    
    def get(uri=nil)
      @server.get("/#{@db_name}/#{uri}")
    end
    
    def put(uri=nil, json=nil)
      @server.put("/#{@db_name}/#{uri}", json)
    end
    
    def post(uri=nil, json=nil)
      @server.post("/#{@db_name}/#{uri}", json)
    end
    
    # Consider replacing with cattr_accessor if offered by web app framework of choice
    def self.std_db
      @@std_db
    end
    
    def self.std_db=(db)
      @@std_db = db
    end
    
    def self.set_std_db(config)
      @@std_db = RelaxDB::Database.new(config[:host], config[:port], config[:db])  
    end

    # Set to scratch as a convenience for using via the console
    @@std_db = RelaxDB::Database.new("localhost", 5984, "scratch")
    
  end
  
end
