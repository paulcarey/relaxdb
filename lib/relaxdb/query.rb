module RelaxDB

  # A Query is used to build the query string made against a view
  # All parameter values are first JSON encoded and then URL encoded
  # Nil values are set to the empty string
  # All parameter calls return self so calls may be chained => q.startkey("foo").endkey("bar").count(2)
  
  #
  # The query object is currently inconsistent with the RelaxDB object idiom. Consider
  #   paul = User.new(:name => "paul").save; Event.new(:host=>paul).save
  # but an event query requires
  #   Event.all.sorted_by(:host_id) { |q| q.key(paul._id) } 
  # rather than
  #   Event.all.sorted_by(:host) { |q| q.key(paul) }  
  # I feel that both forms should be supported
  #
  class Query
    
    @@params = %w(key startkey startkey_docid endkey endkey_docid count update descending skip group group_level)
    
    @@params.each do |param|
      define_method(param.to_sym) do |val|
        # val ||= "" # may cause a bunch of tests to break - think what happens when a user submits an empty key - potential for exposing data
        instance_variable_set("@#{param}".to_sym, val)
        self
      end
    end
    
    def initialize(design_doc, view_name)
      @design_doc = design_doc
      @view_name = view_name
    end
    
    def view_path
      uri = "_view/#{@design_doc}/#{@view_name}"
      
      query = ""
      @@params.each do |param|
        val = instance_variable_get("@#{param}")
        query << "&#{param}=#{::CGI::escape(val.to_json)}" unless val.nil?
      end
    
      uri << query.sub(/^&/, "?")
    end
    
    def merge(paginate_params)
      paginate_params.instance_variables.each do |pp|
        val = paginate_params.instance_variable_get(pp)
        instance_variable_set(pp, val)
      end
    end
        
  end

end
