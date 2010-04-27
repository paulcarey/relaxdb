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
      create_by_att_list "doc", "_count", kls, *atts
    end
    
    def self.by_att_list(kls, *atts)
      create_by_att_list 1, "_sum", kls, *atts
    end
    
    def self.create_by_att_list emit_val, reduce_func, kls, *atts
      class_name = kls[0]
      key = atts.map { |a| "doc.#{a}" }.join(", ")
      key = atts.size > 1 ? key.sub(/^/, "[").sub(/$/, "]") : key
      prop_check = atts.map { |a| "doc.#{a} !== undefined" }.join(" && ")
    
      map = <<-QUERY
      function(doc) {
        var class_match = #{kls_check kls}
        if (class_match && #{prop_check}) {
          emit(#{key}, #{emit_val});
        }
      }
      QUERY
      
      view_name = "#{class_name}_by_" << atts.join("_and_")
      View.new view_name, map, reduce_func      
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
    end
        
  end

end
