module RelaxDB

  class ViewCreator
    
    def self.all
      map = <<-QUERY
      function(doc) {
        if(doc.class !== undefined)
          emit(doc.class, doc);
      }
      QUERY
            
      View.new "all_by_relaxdb_class", map, sum_reduce_func      
    end
    
    def self.by_att_list(class_name, *atts)
      key = atts.map { |a| "doc.#{a}" }.join(", ")
      key = atts.size > 1 ? key.sub(/^/, "[").sub(/$/, "]") : key
      prop_check = atts.map { |a| "doc.#{a} !== undefined" }.join(" && ")
    
      map = <<-QUERY
      function(doc) {
        if(doc.class == "#{class_name}" && #{prop_check}) {
          emit(#{key}, doc);
        }
      }
      QUERY
      
      view_name = "#{class_name}_by_" << atts.join("_and_")
      View.new view_name, map, sum_reduce_func
    end
    
  
    def self.has_n(target_class, relationship_to_client)
      template = <<-MAP_FUNC
      function(doc) {
        if(doc.class == "${target_class}" && doc.${relationship_to_client}_id)
          emit(doc.${relationship_to_client}_id, doc);
      }
      MAP_FUNC
      template.sub!("${target_class}", target_class)
      template.gsub("${relationship_to_client}", relationship_to_client)
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
    
    def self.sum_reduce_func
      <<-QUERY
      function(keys, values, rereduce) {
        if (rereduce) {
          return sum(values);
        } else {
          return values.length;
        }
      }
      QUERY
    end    
    
  end
  
  class View
    
    attr_reader :view_name
        
    def initialize view_name, map_func, reduce_func
      @view_name = view_name
      @map_func = map_func
      @reduce_func = reduce_func
    end
    
    def save
      dd = DesignDocument.get(RelaxDB.dd) 
      dd.add_map_view(@view_name, @map_func)
      dd.add_reduce_view(@view_name, @reduce_func)
      dd.save
    end
    
  end

end
