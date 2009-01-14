module RelaxDB

  class HasManyProxy

    include Enumerable
    
    attr_reader :children
  
    def initialize(client, relationship, opts)
      @client = client 
      @relationship = relationship
      @opts = opts

      @target_class = opts[:class] 
      @relationship_as_viewed_by_target = (opts[:known_as] || client.class.name.snake_case).to_s

      @children = load_children
    end

    def <<(obj)
      return false if @children.include?(obj)

      obj.send("#{@relationship_as_viewed_by_target}=".to_sym, @client)
      if obj.save
        @children << obj
        self
      else
        false
      end
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
        obj.send("#{@relationship_as_viewed_by_target}=".to_sym, nil)
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
    
    def first
      @children[0]
    end
    
    def last
      @children[size-1]
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
    
    def children=(children)
      children.each do |obj|
        obj.send("#{@relationship_as_viewed_by_target}=".to_sym, @client)
      end
      @children = children
    end
  
    def inspect
      @children.inspect
    end
  
  end

end
