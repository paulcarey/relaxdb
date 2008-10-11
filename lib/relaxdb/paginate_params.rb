module RelaxDB

  class PaginateParams
        
    @@params = %w(key startkey startkey_docid endkey endkey_docid count update descending group)
  
    @@params.each do |param|
      define_method(param.to_sym) do |*val|
        if val.empty?
          instance_variable_get("@#{param}")
        else
          instance_variable_set("@#{param}", val[0])
          self
        end
      end
    end
  
    def update(params)
      @order_inverted = params["descending"].nil? ? false : @descending ^ params["descending"]
      @descending = !@descending if @order_inverted

      @endkey = @startkey if @order_inverted
    
      @startkey = params["startkey"] || @startkey
    
      @skip = 1 if params["startkey"]
    end
  
    def order_inverted?
      @order_inverted
    end
      
  end

end