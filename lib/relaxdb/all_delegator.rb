module RelaxDB
  
  #
  # The AllDelegator allows clients to query CouchDB in a natural way
  #   FooDoc.all - returns all docs in CouchDB of type FooDoc
  #   FooDoc.all.sorted_by(:att1, :att2) - returns all docs in CouchDB of type FooDoc sorted by att1, then att2
  #   FooDoc.all.sorted_by(:att1) { |q| q.key("bar") } - returns all docs of type FooDoc where att1 equals "bar"
  #   FooDoc.all.destroy! - does what it says on the tin
  #
  class AllDelegator < Delegator
    
    def initialize(klass)
      super([])
      @klass = klass
    end
    
    def __getobj__
      view_path = "_view/#{@klass}/all"
      map_function = ViewCreator.all(@klass)
      
      @all = RelaxDB::retrieve(view_path, @klass, "all", map_function)      
    end

    def sorted_by(*atts)
      v = SortedByView.new(@klass.name, *atts)

      q = Query.new(@klass.name, v.view_name)
      yield q if block_given?
      
      RelaxDB::retrieve(q.view_path, @klass, v.view_name, v.map_function)      
    end
    
    # Note that this method leaves the corresponding DesignDoc for the associated class intact
    def destroy!
      each do |o| 
        # A reload is required for deleting objects with a self referential references_many relationship
        # This makes all.destroy! very slow. Given that references_many is now deprecated and will
        # soon be removed, the required reload is no longer performed.
        # obj = RelaxDB.load(o._id)
        # obj.destroy!
        
        o.destroy!
      end
    end
            
  end
  
end
