module RelaxDB

  class DesignDocument
  
    def initialize(client_class, data)
      @client_class = client_class
      @data = data
    end
      
    def add_map_view(view_name, function)
      add_view(view_name, "map", function)
    end
    
    def add_reduce_view(view_name, function)
      add_view(view_name, "reduce", function)
    end
    
    def add_validation_func(function)
      @data["validate_doc_update"] = function
      self
    end
    
    def add_view(view_name, type, function)
      @data["views"] ||= {}
      @data["views"][view_name] ||= {}
      @data["views"][view_name][type] = function
      self            
    end
  
    def save
      database = RelaxDB.db    
      resp = database.put(::CGI::escape(@data["_id"]), @data.to_json)
      @data["_rev"] = JSON.parse(resp.body)["rev"]
      self
    end
  
    def self.get(client_class)
      begin
        database = RelaxDB.db
        resp = database.get(::CGI::escape("_design/#{client_class}"))
        DesignDocument.new(client_class, JSON.parse(resp.body))
      rescue => e
        DesignDocument.new(client_class, {"_id" => "_design/#{client_class}"} )
      end
    end  
    
    def destroy!
      # Implicitly prevent the object from being resaved by failing to update its revision
      RelaxDB.db.delete("#{::CGI::escape(@data["_id"])}?rev=#{@data["_rev"]}")
      self      
    end
  
  end
  
end
