module RelaxDB

  class ViewResult < DelegateClass(Array)
    
    attr_reader :offset, :total_rows
  
    def initialize(result_hash)
      objs = RelaxDB.create_from_hash(result_hash)
      
      @offset = result_hash["offset"]
      @total_rows = result_hash["total_rows"]
      
      super(objs)
    end
  
  end

end