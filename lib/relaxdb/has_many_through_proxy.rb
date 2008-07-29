# Methods must take care not to accidentally retrieve the entire object graph
class HasManyThroughProxy
  
  def initialize(client, relationship, opts)
    @client = client
    @relationship = relationship
    
    @target_class = opts[:class] || relationship
    @relationship_to_client = opts[:known_as] # more completely, relationship_of_target_to_client
  end
  
  def <<(obj, reciprocal_invocation=false)
    @peers << obj if @peers
    peer_ids << obj._id
    
    unless reciprocal_invocation
      # Set the other side of the relationship, ensuring this method isn't called again
      obj.send(@relationship_to_client).send(:<<, @client, true) 
    
      # Bulk save to ensure relationship is persisted on both sides
      RelaxDB.bulk_save(@client, obj)
    end
    
    self
  end
  
  # TODO: Should this be called destory
  def delete(obj, reciprocal_invocation=false)
    @peers.delete(obj) if @peers
    deleted = peer_ids.delete(obj._id)
    
    unless reciprocal_invocation
      # Delete on the other side of the relationship, ensuring this method isn't called again
      obj.send(@relationship_to_client).send(:delete, @client, true) 

      # Bulk save to ensure relationship is persisted on both sides
      RelaxDB.bulk_save(@client, obj)
    end
    
    deleted ? obj : nil
  end
  
  def size
    peer_ids.size
  end
  
  def empty?
    peer_ids.empty?
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
  # Called internally by each, and may also be called by clients
  def resolve    
    db = RelaxDB::Database.std_db
    view_path = "_view/#{@client.class}/#{@relationship}?key=\"#{@client._id}\""
    begin
      resp = db.get(view_path)
    rescue => e
      DesignDocument.get(@client.class).add_has_many_through_view(@relationship, @target_class, @relationship_to_client).save
      resp = db.get(view_path)
    end
    
    @peers = []
    data = JSON.parse(resp.body)["rows"]
    data.each do |row|
      @peers << RelaxDB.create_from_hash(row["value"])
    end
    @peers
  end
  
  def inspect
    @client.instance_variable_get("@#{@relationship}".to_sym).inspect
  end
  
  private
  
  def peer_ids
    @client.instance_variable_get("@#{@relationship}".to_sym)
  end
  
end