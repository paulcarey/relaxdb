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
        if (rereduce) {
          return sum(values);
        } else {
          return values.length;
        }
      }
      QUERY
    end
    
    def view_name
      "#{@class_name}_by_" << @atts.join("_and_")
    end
        
    def query(query)
      # If a view contains both a map and reduce function, CouchDB will by default return 
      # the result of the reduce function when queried. 
      # This class automatically creates both map and reduce functions so it can be used by the paginator.
      # In normal usage, this class will be used with map functions, hence reduce is explicitly set 
      # to false if it hasn't already been set.
      query.reduce(false) if query.reduce.nil?
      
      method = query.keys ? :post : :get
      
      begin
        resp = RelaxDB.db.send(method, query.view_path, query.keys)
      rescue => e
        design_doc = DesignDocument.get(RelaxDB.dd) 
        design_doc.add_map_view(view_name, map_function).add_reduce_view(view_name, reduce_function).save
        resp = RelaxDB.db.send(method, query.view_path, query.keys)        
      end

      data = JSON.parse(resp.body)
      ViewResult.new(data)            
    end
  
  end
  
end
