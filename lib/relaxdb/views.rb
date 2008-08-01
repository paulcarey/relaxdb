module RelaxDB

  class ViewCreator
    
    def self.all(target_class)
      template = <<-QUERY
      function(doc) {
        if(doc.class == "${target_class}")
          emit(null, doc);
      }
      QUERY
      template.sub!("${target_class}", target_class.to_s)
    end
  
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

end
