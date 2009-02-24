module RelaxDB
  
  #
  # The AllDelegator allows clients to query CouchDB in a natural way
  #   FooDoc.all - returns all docs in CouchDB of type FooDoc
  #   FooDoc.all.sorted_by(:att1, :att2) - returns all docs in CouchDB of type FooDoc sorted by att1, then att2
  #   FooDoc.all.sorted_by(:att1) { |q| q.key("bar") } - returns all docs of type FooDoc where att1 equals "bar"
  #   FooDoc.all.destroy! - does what it says on the tin
  #   FooDoc.all.size - issues a query to a reduce function that returns the total number of docs for that class
  #
  class AllDelegator < Delegator
    
    def initialize(design_doc)
      super([])
      @design_doc = design_doc
    end
    
    def __getobj__
      view_path = "_view/#{@design_doc}/all?reduce=false"
      map, reduce = ViewCreator.all(@design_doc)
      
      RelaxDB.retrieve(view_path, @design_doc, "all", map, reduce)
    end

    def sorted_by(*atts)
      view = SortedByView.new(@design_doc, *atts)

      query = Query.new(@design_doc, view.view_name)
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
    
    # This is pretty ugly - this pattern is now spread over three 
    # places (sorted_by_view, relaxdb and here)
    # Consolidation needed
    def size
      view_path = "_view/#{@design_doc}/all"
      map, reduce = ViewCreator.all(@design_doc)
      
      begin
        resp = RelaxDB.db.get(view_path)
      rescue => e
        DesignDocument.get(@design_doc).add_map_view("all", map).
          add_reduce_view("all", reduce).save
        resp = RelaxDB.db.get(view_path)
      end
      
      data = JSON.parse(resp.body)
      data["rows"][0] ? data["rows"][0]["value"] : 0
    end
            
  end
  
end
