module RelaxDB
  
  #
  # The AllDelegator allows clients to query CouchDB in a natural way
  #   FooDoc.all - returns all docs in CouchDB of type FooDoc
  #   FooDoc.all.size - issues a query to a reduce function that returns the total number of docs for that class
  #   FooDoc.all.destroy! - TODO - better description
  #
  class AllDelegator < Delegator
    
    def initialize(class_name, params)
      super([])
      @class_name = class_name
      @params = params
    end
    
    def __getobj__
      unless @ids
        params = {:raw => true}.merge @params
        result = RelaxDB.rf_view "#{@class_name}_all", params
        @ids = RelaxDB.ids_from_view result
      end
      @ids
    end
    
    def __setobj__ obj
      # Intentionally empty
    end
    
    def load!
      __getobj__
      @objs = RelaxDB.load! @ids
    end

    def size
      size = RelaxDB.view "#{@class_name}_all", :reduce => true
      size || 0
    end
    
    #
    # TODO - needs updating
    #
    # TODO: destroy in a bulk_save if feasible
    def destroy!
      load!
      @objs.each do |o| 
        # A reload is required for deleting objects with a self referential references_many relationship
        # This makes all.destroy! very slow. Change if needed
        # obj = RelaxDB.load(o._id)
        # obj.destroy!
        
        o.destroy!
      end
    end    
            
  end
  
end
