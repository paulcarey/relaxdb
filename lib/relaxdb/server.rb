module RelaxDB
  
  class HTTP_404 < StandardError; end
  class HTTP_409 < StandardError; end
  class HTTP_412 < StandardError; end
      
  class CouchDB

    attr_reader :logger, :server
        
    # Used for test instrumentation only i.e. to assert that 
    # an expected number of requests have been issued
    attr_accessor :get_count, :put_count, :post_count
        
    def initialize(config)
      @get_count, @post_count, @put_count = 0, 0, 0
      @server = RelaxDB::Server.new(config[:host], config[:port])
      @logger = config[:logger] ? config[:logger] : Logger.new(Tempfile.new('relaxdb.log'))
    end
    
    def use_db(name)
      create_db_if_non_existant(name)
      @db = name
    end
    
    def db_exists?(name)
      @server.get("/#{name}") rescue false
    end
    
    # URL encode slashes e.g. RelaxDB.delete_db "foo%2Fbar"
    def delete_db(name)
      # Close the http connection as CouchDB will keep a file handle to the db open
      # if the http connection remains open - this will result in CouchDB throwing
      # emfile errors after a significant number of databases are deleted.
      @server.close_connection
      
      @logger.info("Deleting database #{name}")
      @server.delete("/#{name}")
    end
    
    def list_dbs
      JSON.parse(@server.get("/_all_dbs").body)
    end
    
    def replicate_db(source, target)
      @logger.info("Replicating from #{source} to #{target}")
      create_db_if_non_existant target      
      # Manual JSON encoding to allow for dbs containing a '/'
      data = %Q({"source":"#{source}","target":"#{target}"})       
      @server.post("/_replicate", data)
    end

    def delete(path=nil)
      @logger.info("DELETE /#{@db}/#{unesc(path)}")
      @server.delete("/#{@db}/#{path}")
    end
    
    def get(path=nil)
      @get_count += 1
      @logger.info("GET /#{@db}/#{unesc(path)}")
      @server.get("/#{@db}/#{path}")
    end
        
    def post(path=nil, json=nil)
      @post_count += 1
      @logger.info("POST /#{@db}/#{unesc(path)} #{json}")
      @server.post("/#{@db}/#{path}", json)
    end
    
    def put(path=nil, json=nil)
      @put_count += 1
      @logger.info("PUT /#{@db}/#{unesc(path)} #{json}")
      @server.put("/#{@db}/#{path}", json)
    end
    
    def uuids(count=1)
      @get_count += 1
      uri = "/_uuids?count=#{count}"
      @logger.info "GET #{uri}"
      @server.get uri
    end
    
    def unesc(path)
      # path
      path ? ::CGI::unescape(path) : ""
    end
    
    def uri
      "#@server" / @db
    end
    
    def name
      @db
    end
    
    def name=(name)
      @db = name
    end
    
    def req_count
      get_count + put_count + post_count
    end
    
    def reset_req_count
      @get_count = @put_count = @post_count = 0
    end
        
    private
    
    def create_db_if_non_existant(name)
      begin
        @server.get("/#{name}")
      rescue
        @server.put("/#{name}", "")
      end
    end
    
  end
        
end
