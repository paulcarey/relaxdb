module RelaxDB

  class ReferencesManyProxy
    
    include Enumerable
  
    def initialize(client, relationship, opts)
      @client = client
      @relationship = relationship
    
      @target_class = opts[:class]
      @relationship_as_viewed_by_target = opts[:known_as].to_s
      
      @peers = resolve
    end
  
    def <<(obj, reciprocal_invocation=false)
      return false if peer_ids.include? obj._id
      
      @peers << obj if @peers
      peer_ids << obj._id
    
      unless reciprocal_invocation
        # Set the other side of the relationship, ensuring this method isn't called again
        obj.send(@relationship_as_viewed_by_target).send(:<<, @client, true) 
    
        # Bulk save to ensure relationship is persisted on both sides
        # TODO: Should this be bulk_save! ? Probably.
        RelaxDB.bulk_save(@client, obj)
      end
    
      self
    end
  
    def clear
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
      @peers.delete(obj)
      peer_ids.delete(obj._id)
    end
        
    def empty?
      peer_ids.empty?
    end

    def size
      peer_ids.size
    end
  
    def [](*args)
      @peers[*args]
    end
  
    def each(&blk)
      @peers.each(&blk)    
    end
      
    def inspect
      @client.instance_variable_get("@#{@relationship}".to_sym).inspect
    end
      
    def peer_ids
      @client.instance_variable_get("@#{@relationship}".to_sym)
    end
  
    alias to_id_a peer_ids
  
    private
    
    # Resolves the actual ids into real objects via a single GET to CouchDB
    def resolve
      design_doc = RelaxDB.dd
      view_name = "#{@client.class}_#{@relationship}"
      view_path = "_view/#{design_doc}/#{view_name}?key=\"#{@client._id}\""
      map_function = ViewCreator.has_many_through(@target_class, @relationship_as_viewed_by_target)
      @peers = RelaxDB.retrieve(view_path, design_doc, view_name, map_function)
    end
    
  end
  
end
