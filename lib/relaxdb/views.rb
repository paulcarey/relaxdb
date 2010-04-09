module RelaxDB

  class ViewCreator
    
    def self.all(kls)
      class_name = kls[0]
      map = <<-QUERY
      function(doc) {        
        var class_match = #{kls_check kls}
        if (class_match) {
          emit(doc._id, 1);
        }
      }
      QUERY
            
      View.new "#{class_name}_all", map, "_sum"
    end
    
    def self.docs_by_att_list(kls, *atts)
      class_name = kls[0]
      key = atts.map { |a| "doc.#{a}" }.join(", ")
      key = atts.size > 1 ? key.sub(/^/, "[").sub(/$/, "]") : key
      prop_check = atts.map { |a| "doc.#{a} !== undefined" }.join(" && ")
    
      map = <<-QUERY
      function(doc) {
        var class_match = #{kls_check kls}
        if (class_match && #{prop_check}) {
          emit(#{key}, doc);
        }
      }
      QUERY
      
      view_name = "#{class_name}_by_" << atts.join("_and_")
      View.new view_name, map, "_count"
    end
    
  
    def self.has_n(client_class, relationship, target_class, relationship_to_client)
      map = <<-QUERY
        function(doc) {
          if (doc.relaxdb_class == "#{target_class}" && doc.#{relationship_to_client}_id)
            emit(doc.#{relationship_to_client}_id, doc);
        }
      QUERY
      
      view_name = "#{client_class}_#{relationship}"
      View.new view_name, map
    end
  
    def self.references_many(client_class, relationship, target_class, peers)
      map = <<-QUERY
        function(doc) {
          if (doc.relaxdb_class == "#{target_class}" && doc.#{peers}) {
            var i;
            for(i = 0; i < doc.#{peers}.length; i++) {
              emit(doc.#{peers}[i], doc);
            }
          }
        }
      QUERY
      
      view_name = "#{client_class}_#{relationship}"
      View.new view_name, map
    end
    
    def self.kls_check kls
      kls_names = kls.map{ |k| %Q("#{k}") }.join(",")
      "[#{kls_names}].indexOf(doc.relaxdb_class) >= 0;"
    end
    
  end
  
  class View
    
    attr_reader :view_name
        
    def initialize view_name, map_func, reduce_func = nil
      @view_name = view_name
      @map_func = map_func
      @reduce_func = reduce_func
    end
    
    def self.design_doc
      @design_doc ||= DesignDocument.get(RelaxDB.dd) 
    end
    
    #
    # A convenience for tests that create their own views
    #
    def self.reset
      @design_doc = nil
    end
        
    def add_to_design_doc
      dd = View.design_doc
      dd.add_map_view(@view_name, @map_func)
      dd.add_reduce_view(@view_name, @reduce_func) if @reduce_func
      # dd.save
    end
    
    # def exists?
    #   dd = design_doc
    #   dd.data["views"] && dd.data["views"][@view_name]
    # end
    
  end

end
