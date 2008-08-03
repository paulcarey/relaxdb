module RelaxDB

  # Note - methods must take care not to accidentally retrieve the entire object graph
  class ReferencesManyProxy
    
    include Enumerable
  
    def initialize(client, relationship, opts)
      @client = client
      @relationship = relationship
    
      @target_class = opts[:class]
      @relationship_as_viewed_by_target = opts[:known_as].to_s # more completely, relationship_of_target_to_client
    end
  
    def <<(obj, reciprocal_invocation=false)
      @peers << obj if @peers
      peer_ids << obj._id
    
      unless reciprocal_invocation
        # Set the other side of the relationship, ensuring this method isn't called again
        obj.send(@relationship_as_viewed_by_target).send(:<<, @client, true) 
    
        # Bulk save to ensure relationship is persisted on both sides
        RelaxDB.bulk_save(@client, obj)
      end
    
      self
    end
  
    def clear
      resolve
      @peers.each do |peer|
        peer.send(@relationship_as_viewed_by_target).send(:delete_from_self, @client)
      end
    
      # Important to resolve in the database before in memory, although an examination of the
      # contents of the bulk_save will look wrong as this object will still list all its peers
      RelaxDB.bulk_save(@client, *@peers)
      
      peer_ids.clear
      @peers.clear
    end
    
    def delete(obj)
      deleted = obj.send(@relationship_as_viewed_by_target).send(:delete_from_self, @client)
      if deleted
        delete_from_self(obj)
        RelaxDB.bulk_save(@client, obj)
      end
      deleted
    end
  
    def delete_from_self(obj)
      @peers.delete(obj) if @peers
      peer_ids.delete(obj._id)
    end
        
    def empty?
      peer_ids.empty?
    end

    def size
      peer_ids.size
    end
  
    def [](*args)
      resolve
      @peers[*args]
    end
  
    def each(&blk)
      resolve
      @peers.each(&blk)    
    end
  
    # Resolves the actual ids into real objects via a single GET to CouchDB
    # Called internally by each, and may also be called by clients. Bad idea, invariant between 
    # peers and peer_ids could easily be violated
    def resolve
      design_doc = @client.class
      view_name = @relationship
      view_path = "_view/#{design_doc}/#{view_name}?key=\"#{@client._id}\""
      map_function = ViewCreator.has_many_through(@target_class, @relationship_as_viewed_by_target)
      @peers = RelaxDB.retrieve(view_path, design_doc, view_name, map_function)
    end
    
    def inspect
      @client.instance_variable_get("@#{@relationship}".to_sym).inspect
    end
  
    private
  
    def peer_ids
      @client.instance_variable_get("@#{@relationship}".to_sym)
    end
    
  end
  
end
