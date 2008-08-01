module RelaxDB

  class DesignDocument
  
    def initialize(client_class, data)
      @client_class = client_class
      @data = data
    end
      
    def add_view(view_name, map_function)
      @data["views"] ||= {}
      @data["views"][view_name] ||= {}
      @data["views"][view_name]["map"] = map_function
      self
    end
  
    def save
      database = RelaxDB.db    
      resp = database.put("#{@data['_id']}", @data.to_json)
      @data["_rev"] = JSON.parse(resp.body)["rev"]
      self
    end
  
    def self.get(client_class)
      begin
        database = RelaxDB.db
        resp = database.get("_design/#{client_class}")
        DesignDocument.new(client_class, JSON.parse(resp.body))
      rescue => e
        DesignDocument.new(client_class, {"_id" => "_design/#{client_class}"} )
      end
    end  
  
  end
  
end
