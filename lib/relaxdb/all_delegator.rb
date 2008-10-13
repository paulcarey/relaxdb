module RelaxDB
  
  #
  # The AllDelegator allows clients to query CouchDB in a natural way
  #   FooDoc.all - returns all docs in CouchDB of type FooDoc
  #   FooDoc.all.sorted_by(:att1, :att2) - returns all docs in CouchDB of type FooDoc sorted by att1, then att2
  #   FooDoc.all.sorted_by(:att1) { |q| q.key("bar") } - returns all docs of type FooDoc where att1 equals "bar"
  #   FooDoc.all.destroy! - does what it says on the tin
  #
  class AllDelegator < Delegator
    
    def initialize(class_name)
      super([])
      @class_name = class_name
    end
    
    def __getobj__
      view_path = "_view/#{@class_name}/all"
      map_function = ViewCreator.all(@class_name)
      
      @all = RelaxDB.retrieve(view_path, @class_name, "all", map_function)      
    end

    def sorted_by(*atts)
      view = SortedByView.new(@class_name, *atts)

      query = Query.new(@class_name, view.view_name)
      yield query if block_given?
      
      view.query(query)
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
