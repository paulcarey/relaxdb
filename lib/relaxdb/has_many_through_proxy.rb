class HasManyThroughProxy
  
  def initialize(client, relationship, opts)
    @client = client
    @relationship = relationship
    
    @target_class = opts[:class] || relationship
    @relationship_to_client = opts[:known_as] # more completely, relationship_of_target_to_client
  end
  
  def <<(obj, reciprocal_invocation=false)
    peer_ids << obj._id
    
    # Set the other side of the relationship, ensuring this method isn't called again
    obj.send(@relationship_to_client).send(:<<, @client, true) unless reciprocal_invocation
    peer_ids
  end
  
  def size
    peer_ids.size
  end
  
  def [](*args)
    peer_ids[*args] # Retrieve the actual tag ??? Let's not go for n+1 DataMapper.all heuristic?
  end
  
  def inspect
    @client.instance_variable_get("@#{@relationship}".to_sym).inspect
  end
  
  private
  
  def peer_ids
    @client.instance_variable_get("@#{@relationship}".to_sym)
  end
  
end