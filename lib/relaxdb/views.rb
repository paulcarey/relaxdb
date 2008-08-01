module RelaxDB

  class ViewCreator
    
    def self.has_n(target_class, relationship_to_client)
      template = <<-MAP_FUNC
      function(doc) {
        if(doc.class == "${target_class}")
          emit(doc.${relationship_to_client}_id, doc);
      }
      MAP_FUNC
      template.sub!("${target_class}", target_class)
      template.sub("${relationship_to_client}", relationship_to_client)
    end
  
    def self.all(target_class)
      map_template = <<-QUERY
      function(doc) {
        if(doc.class == "${target_class}")
          emit(null, doc);
      }
      QUERY
      map_template.sub!("${target_class}", target_class.to_s)
    end
  
    def self.has_many_through(target_class, peers)
      template = <<-MAP_FUNC
        function(doc) {
          if(doc.class == "${target_class}" && doc.${peers}) {
            var i;
            for(i = 0; i < doc.${peers}.length; i++) {
              emit(doc.${peers}[i], doc);
            }
          }
        }
      MAP_FUNC
      template.sub!("${target_class}", target_class).gsub!("${peers}", peers)
    end
    
  end

  # TODO: Integrate more closely with RelaxDB::Document - a little too much repitition, I think
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