module RelaxDB

  class DesignDocument
    
    attr_reader :data
  
    def initialize(design_doc_name, data)
      @design_doc_name = design_doc_name
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
      resp = database.put(@data["_id"], @data.to_json)
      @data["_rev"] = JSON.parse(resp.body)["rev"]
      self
    end
  
    def self.get(design_doc_name)
      begin
        database = RelaxDB.db
        resp = database.get("_design/#{design_doc_name}")
        DesignDocument.new(design_doc_name, JSON.parse(resp.body))
      rescue HTTP_404
        DesignDocument.new(design_doc_name, {"_id" => "_design/#{design_doc_name}"} )
      end
    end  
    
    def destroy!
      # Implicitly prevent the object from being resaved by failing to update its revision
      RelaxDB.db.delete("#{@data["_id"]}?rev=#{@data["_rev"]}")
      self      
    end
  
  end
  
end
