class HasManyProxy

  include Enumerable
  
  def initialize(client, relationship, opts)
    @client = client 
    @relationship = relationship
    @opts = opts # need to resolve target class here

    @target_class = opts[:class] || relationship
    @relationship_to_client = opts[:known_as] || client.class.name.downcase # implicitly - as viewed by target

    @children = load_children
  end

  def <<(obj)
    obj.instance_variable_set("@#{@relationship_to_client}".to_sym, @client)
    obj.save
    @children << obj
  end
  
  def clear
    @children.each do |c|
      break_back_link c
    end
    @children.clear
  end
  
  def delete(obj)
    obj = @children.delete(obj)
    break_back_link(obj) if obj
  end
  
  def break_back_link(obj)
    if obj
      # Revise this logic - could it be simplified?
      obj.send("#{@relationship_to_client}=".to_sym, nil)
      obj.instance_variable_set("@#{@relationship_to_client}".to_sym, nil)
      obj.instance_variable_set("@#{@relationship_to_client}_id".to_sym, nil)
      obj.save
    end
  end
  
  def empty?
    @children.empty?
  end
  
  def size
    @children.size
  end
  
  def [](*args)
    @children[*args]
  end
  
  def each(&blk)
    @children.each(&blk)
  end
  
  def reload
    @children = load_children
  end
  
  def load_children
    database = RelaxDB::Database.std_db
    view_path = "_view/#{@client.class}/#{@relationship}?key=\"#{@client._id}\""
    begin
      resp = database.get(view_path)
    rescue => e
      DesignDocument.get(@client.class).add_view(@relationship, @target_class, @relationship_to_client).save
      resp = database.get(view_path)
    end
    
    @children = []
    data = JSON.parse(resp.body)["rows"]
    data.each do |row|
      @children << RelaxDB.create_from_hash(row["value"])
    end
    @children
  end
  
  def inspect
    @children.inspect
  end
  
end
