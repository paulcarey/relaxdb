module RelaxDB

  class HasManyProxy

    include Enumerable
  
    def initialize(client, relationship, opts)
      @client = client 
      @relationship = relationship
      @opts = opts

      @target_class = opts[:class] 
      @relationship_as_viewed_by_target = (opts[:known_as] || client.class.name.downcase).to_s

      @children = load_children
    end

    def <<(obj)
      obj.instance_variable_set("@#{@relationship_as_viewed_by_target}".to_sym, @client)
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
        obj.send("#{@relationship_as_viewed_by_target}=".to_sym, nil)
        obj.instance_variable_set("@#{@relationship_as_viewed_by_target}".to_sym, nil)
        obj.instance_variable_set("@#{@relationship_as_viewed_by_target}_id".to_sym, nil)
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
      view_path = "_view/#{@client.class}/#{@relationship}?key=\"#{@client._id}\""
      design_doc = @client.class
      view_name = @relationship
      map_function = ViewCreator.has_n(@target_class, @relationship_as_viewed_by_target)
      @children = RelaxDB.retrieve(view_path, design_doc, view_name, map_function)
    end
  
    def inspect
      @children.inspect
    end
  
  end

end
