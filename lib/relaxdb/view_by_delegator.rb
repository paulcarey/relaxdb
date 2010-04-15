module RelaxDB
  
  class ViewByDelegator < Delegator
    
    def initialize(view_name, opts)
      super([])
      @view_name = view_name
      @opts = opts
    end
    
    def __getobj__
      unless @ids
        @opts[:raw] = true
        @ids = RelaxDB.doc_ids @view_name, @opts
      end
      @ids
    end
    
    def __setobj__ obj
      # Intentionally empty
    end
    
    def load!
      if @ids
        RelaxDB.load! @ids
      else
        @opts[:include_docs] = true
        RelaxDB.docs @view_name, @opts
      end
    end
                
  end
  
end
