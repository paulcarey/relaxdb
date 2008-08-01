module RelaxDB

  # Potential exists for optimsing when the target is explicitly set to nil
  class HasOneProxy
  
    def initialize(client, relationship)
      @client = client
      @relationship = relationship
      @target = nil
      @relationship_as_viewed_by_target = client.class.to_s.downcase
    end
    
    def target
      return @target if @target

      @target = @client.instance_variable_get("@#{@relationship}")
      return @target if @target
    
      @target = load_target_from_database
    end
  
    # All database changes performed by this method would ideally be done in a transaction
    # Consider bulk update
    def target=(new_target)
      # Nullify any existing relationship on assignment
      old_target = target
      if old_target
        old_target.send("#{@relationship_as_viewed_by_target}=".to_sym, nil)
        old_target.instance_variable_set("@#{@relationship_as_viewed_by_target}".to_sym, nil)
        old_target.instance_variable_set("@#{@relationship_as_viewed_by_target}_id".to_sym, nil)
        old_target.save
      end
    
      @target = new_target
      if not @target.nil?
        @target.instance_variable_set("@#{@relationship_as_viewed_by_target}".to_sym, @client)
        @target.save
      end
    end
  
    def load_target_from_database
      database = RelaxDB.db
      view_path = "_view/#{@client.class}/#{@relationship}?key=\"#{@client._id}\""
      begin
        resp = database.get(view_path)
      rescue => e
        DesignDocument.get(@client.class).add_view(@relationship).save
        resp = database.get(view_path)
      end
      data = JSON.parse(resp.body)["rows"][0]
      data ? RelaxDB.create_from_hash(data["value"]) : nil
    end
      
  end

end
