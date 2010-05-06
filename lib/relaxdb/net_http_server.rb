module RelaxDB

  class Server
    
    attr_reader :host, :port
      
    def initialize(host, port)
      @host = host
      @port = port
    end
    
    def cx
      unless @cx && @cx.active?
        @cx = Net::HTTP.start(@host, @port)
      end
      @cx
    end
    
    def close_connection
      @cx.finish if @cx
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
      begin
        res = cx.request(req)
      rescue
        @cx = nil
        res = cx.request(req)
      end
      
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
      msg = "#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}"
      begin
        klass = RelaxDB.const_get("HTTP_#{res.code}")
        e = klass.new(msg)
      rescue
        e = RuntimeError.new(msg)
      end

      raise e
    end
  end
  
end