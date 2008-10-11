module RelaxDB

  # Represents a CouchDB view, which is implicitly sorted by key
  # The view name is determined by sort attributes  
  class SortedByView

    def initialize(class_name, *atts)
      @class_name = class_name
      @atts = atts
    end

    def map_function
      # To guard against non existing attributes in older documents, an OR with an object literal 
      # is inserted for each emitted key. The guard can be emitted in 0.9 trunk.
      # The object literal is the lowest sorting JSON category
        
      # Create the key from the attributes, wrapping it in [] if the key is composite
      raw = @atts.inject("") { |m,v| m << "(doc.#{v}||{}), " }
      refined = raw[0, raw.size-2]
      pure = @atts.size > 1 ? refined.sub(/^/, "[").sub(/$/, "]") : refined
    
      <<-QUERY
      function(doc) {
        if(doc.class == "#{@class_name}") {
          emit(#{pure}, doc);
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
      name = "all_sorted_by#{suffix}"
    end
    
    def reduce_view_name
      "reduce_by#{suffix}"
    end
    
    def suffix
      s = @atts.inject("") do |s, att|
        s << "_#{att}_and"
      end
      s[0, s.size-4]
    end
  
  end
  
end
