module RelaxDB

  class ReferencesProxy

    attr_reader :target
  
    def initialize(client, relationship)
      @client = client
      @relationship = relationship
      @target = nil
    end
  
    def target
      return @target if @target
            
      id = @client.data["#{@relationship}_id"]
      @target = RelaxDB.load(id) if id
    end
  
    def target=(new_target)
      id = new_target ? new_target._id : nil
      @client.data["#{@relationship}_id"] = id
      
      @target = new_target
    end
    
  end

end