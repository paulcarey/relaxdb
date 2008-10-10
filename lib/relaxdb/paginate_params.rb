module RelaxDB

  class PaginateParams
    
    attr_reader :default_descending
    
    @@params = %w(key startkey startkey_docid endkey endkey_inverted endkey_docid count update descending group)
  
    @@params.each do |param|
      define_method(param.to_sym) do |val|
        instance_variable_set("@#{param}".to_sym, val)
        self
      end
    end
  
    def update(params)
      @startkey = params["startkey"] || @startkey

      @default_descending = @descending
      @order_inverted = params["descending"].nil? ? false : @descending ^ params["descending"]
      @descending = !@descending if @order_inverted

      @endkey = @endkey_inverted if @order_inverted
    
      @skip = 1 if params["startkey"]
    end
  
    def order_inverted?
      @order_inverted
    end
      
  end

end