module RelaxDB
  
  class AllDelegator < Delegator
    
    def initialize(klass)
      super(nil)
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

    
    # Note that this method leaves the corresponding DesignDoc for this class intact
    def destroy!
      self.each do |o| 
        # A reload is required for deleting objects with a self referential references_many relationship
        # when a cache is not used. This makes destroy_all! very slow. Given that references_many is
        # now deprecated and will soon be removed, the required reload is no longer performed.
        # obj = RelaxDB.load(o._id)
        # obj.destroy!
        
        o.destroy!
      end
    end
    
    def foo
      "foo"
    end
    
    # Defined so this may be used in irb
    # def inspect
    #   @all ? @all : "uninitialized"
    # end
    
  end
  
end
