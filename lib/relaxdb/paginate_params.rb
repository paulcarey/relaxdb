module RelaxDB

  class PaginateParams
        
    @@params = %w(key startkey startkey_docid endkey endkey_docid limit update descending group reduce include_docs)
  
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
    
    def initialize(params)
      params.each { |k, v| send(k, v) }
      
      # If a client hasn't explicitly set descending, set it to the CouchDB default
      @descending = false if @descending.nil?
    end
  
    def update(params)
      @order_inverted = params[:descending].nil? ? false : @descending ^ params[:descending]
      @descending = !@descending if @order_inverted

      @endkey = @startkey if @order_inverted
    
      @startkey = params[:startkey] || @startkey
    
      @skip = 1 if params[:startkey]
      
      @startkey_docid = params[:startkey_docid] if params[:startkey_docid]
      @endkey_docid = params[:endkey_docid] if params[:endkey_docid]
    end
  
    def order_inverted?
      @order_inverted
    end
    
    def invalid?
      # Simply because allowing either to be omitted increases the complexity of the paginator
      @startkey_set && @endkey_set ? nil : "Both startkey and endkey must be set"
    end
    alias error_msg invalid?
      
  end

end