module RelaxDB

  class HasOneProxy
  
    def initialize(client, relationship)
      @client = client
      @relationship = relationship
      @target_class = @relationship.to_s.camel_case      
      @relationship_as_viewed_by_target = client.class.name.snake_case
      
      @target = nil
    end
    
    def target
      return @target if @target    
      @target = load_target
    end
  
    # All database changes performed by this method would ideally be done in a transaction
    def target=(new_target)
      # Nullify any existing relationship on assignment
      old_target = target
      if old_target
        old_target.send("#{@relationship_as_viewed_by_target}=".to_sym, nil)
        old_target.save
      end
    
      @target = new_target
      unless @target.nil?
        @target.send("#{@relationship_as_viewed_by_target}=".to_sym, @client)
        @target.save
      end
    end
  
    def load_target
      view_name = "#{@client.class}_#{@relationship}"
      RelaxDB.view(view_name, :key => @client._id).first
    end
        
  end

end
