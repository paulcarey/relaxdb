module RelaxDB

  # A Query is used to build the query string made against a view
  # All parameter values are first JSON encoded and then URL encoded
  # Nil values are set to the empty string
  
  class Query
    
    # keys is not included in the standard param as it is significantly different from the others
    @@params = %w(key startkey startkey_docid endkey endkey_docid limit update 
      descending skip group group_level reduce include_docs batch)
    
    @@params.each do |param|
      define_method(param.to_sym) do |*val|
        if val.empty?
          instance_variable_get("@#{param}")
        else 
          instance_variable_set("@#{param}", val[0])
          # null is meaningful to CouchDB. _set allows us to know that a param has been set, even to nil        
          instance_variable_set("@#{param}_set", true)
          self
        end
      end
    end
        
    def initialize view_name, params = {}      
      @view_name = view_name
      params.each { |k, v| send k, v }
    end
    
    def keys(keys=nil)
      if keys.nil?
        @keys
      else 
        @keys = { :keys => keys }.to_json
        self
      end
    end
    
    # If set to true RelaxDB.view will return unprocessed data
    def raw(val = nil)
      if val.nil?
        @raw
      else
        @raw = val
        self
      end
    end
    
    def view_path
      uri = (@view_name =~ /^_/) ? @view_name : "_design/#{RelaxDB.dd}/_view/#{@view_name}"
      
      query = ""
      @@params.each do |param|
        val_set = instance_variable_get("@#{param}_set")
        if val_set
          val = instance_variable_get("@#{param}")
          val = val.to_json unless ["startkey_docid", "endkey_docid"].include?(param)
          query << "&#{param}=#{::CGI::escape(val)}" 
        end
      end
    
      uri << query.sub(/^&/, "?")
    end
    
    def merge(paginate_params)
      paginate_params.instance_variables.each do |pp|
        val = paginate_params.instance_variable_get(pp)
        method_name = pp[1, pp.length]
        send(method_name, val) if @@params.include? method_name
      end
    end
        
  end

end
