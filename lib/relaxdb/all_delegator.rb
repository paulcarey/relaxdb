module RelaxDB
  
  #
  # The AllDelegator allows clients to query CouchDB in a natural way
  #   FooDoc.all - returns all docs in CouchDB of type FooDoc
  #   FooDoc.all.size - issues a query to a reduce function that returns the total number of docs for that class
  #   FooDoc.all.destroy! - does what it says on the tin
  #
  class AllDelegator < Delegator
    
    def initialize(class_name, params)
      super([])
      @class_name = class_name
      @objs = RelaxDB.view "all_by_relaxdb_class", params
    end
    
    def __getobj__
      @objs
    end

    def sorted_by(*atts)
      view = SortedByView.new(@class_name, *atts)

      query = Query.new(view.view_name)
      yield query if block_given?
      
      view.query(query)
    end
    
    # TODO: destroy in a bulk_save if feasible
    def destroy!
      @objs.each do |o| 
        # A reload is required for deleting objects with a self referential references_many relationship
        # This makes all.destroy! very slow. Change if needed
        # obj = RelaxDB.load(o._id)
        # obj.destroy!
        
        o.destroy!
      end
    end
    
    def size
      size = RelaxDB.view "all_by_relaxdb_class", :key => @class_name, :reduce => true
      size || 0
    end
            
  end
  
end
