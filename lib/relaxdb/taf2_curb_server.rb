module RelaxDB

  class Server
    class Response
      attr_reader :body
      def initialize body
        @body = body
      end
    end

    attr_reader :host, :port  
    
    def initialize(host, port)
      @host, @port = host, port
    end
    
    def close_connection
      # Impl only in net_http as connections are reused
    end

    def delete(uri)
      request(uri, 'delete'){ |c| c.http_delete}
    end

    def get(uri)
      request(uri, 'get'){ |c| c.http_get}
    end

    def put(uri, json)
      request(uri, 'put') do |c|
        c.headers['content-type'] = 'application/json'
        c.http_put json
      end
    end

    def post(uri, json)
      request(uri, 'post') do |c|
        c.headers['content-type'] = 'application/json'
        c.http_post json
      end
    end

    def request(uri, method)
      c = Curl::Easy.new "http://#{@host}:#{@port}#{uri}"
      yield c

      if c.response_code < 200 || c.response_code >= 300
        status_line = c.header_str.split('\r\n').first
        msg = "#{c.response_code}:#{status_line}\nMETHOD:#{method}\nURI:#{uri}\n#{c.body_str}"
        begin
          klass = RelaxDB.const_get("HTTP_#{c.response_code}")
          e = klass.new(msg)
        rescue
          e = RuntimeError.new(msg)
        end

        raise e
      end
      Response.new c.body_str
    end

    def to_s
      "http://#{@host}:#{@port}/"
    end

  end
  
end
