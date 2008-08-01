module RelaxDB

  class BelongsToProxy

    attr_reader :target
  
    def initialize(client, relationship)
      @client = client
      @relationship = relationship
      @target = nil
    end
  
    def target
      # It may be wrong to cache the target...
      return @target if @target
    
      # The relative importance of a relationship to its _id surrogate is resolved
      # both here - when the object is accessed, and when its serialized for saving via to_json
      @target = @client.instance_variable_get("@#{@relationship}")
      return @target if @target
        
      id = @client.instance_variable_get("@#{@relationship}_id")
      # target may already be loaded => save semantics are not perfect
      @target = RelaxDB.load(id) if id
    end
  
    # Not convinced by the semantics of this method. Revise.
    def target=(new_target)
      @client.instance_variable_set("@#{@relationship}", new_target)
      @target = new_target
    end
    
  end

end