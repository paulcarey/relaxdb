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
    
    def to_s
      "http://#{@host}:#{@port}/"
    end
    
    private

    def handle_error(req, res)
      e = RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
      raise e
    end
  end
      
  class CouchDB
        
    def initialize(config)
      @server = RelaxDB::Server.new(config[:host], config[:port])
      @logger = config[:logger] ? config[:logger] : Logger.new(Tempfile.new('couchdb.log'))
      UUID.config({:logger => @logger})
    end
    
    def use_db(name)
      begin
        @server.get("/#{name}")
      rescue
        @server.put("/#{name}", "")
      end
      @db = name
    end
    
    def delete_db(name)
      @server.delete("/#{name}")
    end
    
    def list_dbs
      JSON.parse(@server.get("/_all_dbs").body)
    end
    
    def delete(path=nil)
      @logger.info("DELETE /#{@db}/#{unesc(path)}")
      @server.delete("/#{@db}/#{path}")
    end
    
    def get(path=nil)
      @logger.info("GET /#{@db}/#{unesc(path)}")
      @server.get("/#{@db}/#{path}")
    end
        
    def post(path=nil, json=nil)
      @logger.info("POST /#{@db}/#{unesc(path)} #{json}")
      @server.post("/#{@db}/#{path}", json)
    end
    
    def put(path=nil, json=nil)
      @logger.info("PUT /#{@db}/#{unesc(path)} #{json}")
      @server.put("/#{@db}/#{path}", json)
    end
    
    def unesc(path)
       path ? ::CGI::unescape(path) : ""
    end
    
    def uri
      "#@server" / @db
    end
    
    def name
      @db
    end
    
  end
        
end
