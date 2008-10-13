module RelaxDB

  # Represents a CouchDB view, which is implicitly sorted by key
  # The view name is determined by sort attributes  
  class SortedByView

    def initialize(class_name, *atts)
      @class_name = class_name
      @atts = atts
    end

    def map_function
      key = @atts.map { |a| "doc.#{a}" }.join(", ")
      key = @atts.size > 1 ? key.sub(/^/, "[").sub(/$/, "]") : key
    
      <<-QUERY
      function(doc) {
        if(doc.class == "#{@class_name}") {
          emit(#{key}, doc);
        }
      }
      QUERY
    end
    
    def reduce_function
      <<-QUERY
      function(keys, values, rereduce) {
        return values.length;
      }
      QUERY
    end
    
    def view_name
      s = @atts.inject("all_sorted_by") do |s, att|
        s << "_#{att}_and"
      end
      s[0, s.size-4]
    end
        
    def query(query)
      # If a view contains both a map and reduce function, CouchDB will by default return 
      # the result of the reduce function when queried. 
      # This class automatically creates both map and reduce functions so it can be used by the paginator.
      # In normal usage, this class will be used with map functions, hence reduce is explicitly set to false.
      query.reduce(false) if query.reduce.nil?
      
      begin
        resp = RelaxDB.db.get(query.view_path)
      rescue => e
        design_doc = DesignDocument.get(@class_name) 
        design_doc.add_map_view(view_name, map_function).add_reduce_view(view_name, reduce_function).save
        resp = RelaxDB.db.get(query.view_path)
      end

      data = JSON.parse(resp.body)
      ViewResult.new(data)            
    end
  
  end
  
end
