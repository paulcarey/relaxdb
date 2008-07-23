module RelaxDB
    
  class Document
    
    # Define properties and property methods
    
    def self.property(prop)
      # Class instance varibles are not inherited, so the default properties must be explicitly listed 
      # Perhaps a better solution exists. Revise
      @properties ||= [:_id, :_rev]
      @properties << prop

      define_method(prop) do
        instance_variable_get("@#{prop}".to_sym)
      end

      define_method("#{prop}=") do |val|
        instance_variable_set("@#{prop}".to_sym, val)
      end
    end

    def self.properties
      # Don't force clients to check that it's instantiated
      @properties ||= []
    end

    def properties
      self.class.properties
    end
    
    # Specifying these properties here is kinda ugly. Consider a better solution.
    property :_id 
    property :_rev    
    
    def initialize(hash=nil)
      # The default _id will be overwritten if loaded from RelaxDB
      self._id = UuidGenerator.uuid 
      set_attributes(hash) if hash
    end
    
    def set_attributes(data)
      data.each do |key, val|
        # Only set instance variables on creation - object references are resolved on demand
        instance_variable_set("@#{key}".to_sym, val)
      end
      
      if instance_variable_defined? :@created_at 
        time = ParseDate.parsedate(@created_at)
        @created_at = Time.local(*time)
      end
    end  
    
    def inspect
      s = "#<#{self.class}:#{self.object_id}"
      properties.each do |prop|
        prop_val = instance_variable_get("@#{prop}".to_sym)
        s << ", #{prop}: #{prop_val}" if prop_val
      end
      belongs_to_rels.each do |relationship|
        id = instance_variable_get("@#{relationship}_id".to_sym)
        if id
          s << ", #{relationship}_id: #{id}" if id
        else 
          obj = instance_variable_get("@#{relationship}".to_sym)
          s << ", #{relationship}_id: #{obj._id}" if obj
        end
      end
      s << ">"
    end
            
    def to_json
      data = {}
      # Order is important - this codifies the relative importance of a relationship to its _id surrogate
      # TODO: Revise - loading a parent just so the child can be saved could be considered donkey coding
      belongs_to_rels.each do |relationship|
        parent = send(relationship)
        if parent
          data["#{relationship}_id"] = parent._id
        else
          id = instance_variable_get("@#{relationship}_id".to_sym)
          data["#{relationship}_id"] = id if id
        end
      end
      properties.each do |prop|
        prop_val = instance_variable_get("@#{prop}".to_sym)
        data["#{prop}"] = prop_val if prop_val
      end
      data["class"] = self.class.name
      data.to_json      
    end
    
    def save
      if methods.include? "created_at"
        now = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        instance_variable_set(:@created_at, now) if _rev.nil?
      end
      
      resp = RelaxDB::Database.std_db.put("#{_id}", to_json)
      self._rev = JSON.parse(resp.body)["rev"]
      self
    end  
    
    # has_many methods

    def has_many_proxy(rel_name, opts=nil)
      proxy_sym = "@proxy_#{rel_name}".to_sym
      proxy = instance_variable_get(proxy_sym)
      proxy ||= HasManyProxy.new(self, rel_name, opts)
      instance_variable_set(proxy_sym, proxy)
      proxy
    end
   
    def self.has_many(relationship, opts=nil)
      define_method(relationship) do
        has_many_proxy(relationship, opts)
      end
      
      define_method("#{relationship}=") do
        raise "You may not currently assign to a has_many relationship - to be implemented"
      end      
    end
    
    # has_one methods

    def has_one_proxy(rel_name)
      proxy_sym = "@proxy_#{rel_name}".to_sym
      proxy = instance_variable_get(proxy_sym)
      proxy ||= HasOneProxy.new(self, rel_name)
      instance_variable_set(proxy_sym, proxy)
      proxy
    end
    
    def self.has_one(rel_name, opts=nil)
      define_method(rel_name) do        
        has_one_proxy(rel_name).target
      end
      
      define_method("#{rel_name}=") do |new_target|
        has_one_proxy(rel_name).target = new_target
      end
    end
    
    # belongs_to methods
    
    # Creates and returns the proxy for the named relationship
    def belongs_to_proxy(rel_name)
      proxy_sym = "@proxy_#{rel_name}".to_sym
      proxy = instance_variable_get(proxy_sym)
      proxy ||= BelongsToProxy.new(self, rel_name)
      instance_variable_set(proxy_sym, proxy)
      proxy
    end
    
    def self.belongs_to(rel_name)
      @belongs_to_rels ||= []
      @belongs_to_rels << rel_name

      define_method(rel_name) do
        belongs_to_proxy(rel_name).target
      end
      
      define_method("#{rel_name}=") do |new_target|
        belongs_to_proxy(rel_name).target = new_target
      end
    end
    
    def self.belongs_to_rels
      # Don't force clients to check that it's instantiated
      @belongs_to_rels ||= []
    end
    
    def belongs_to_rels
      self.class.belongs_to_rels
    end
    
    def self.all(opts={})
      database = RelaxDB::Database.std_db
      order = opts[:order]
      if order.to_s[/desc/]
        order = "descending=true"
      else
        order = ""
      end  
        
      view_path = "_view/#{self}/all?#{order}"
      begin
        resp = database.get(view_path)
      rescue => e
        DesignDocument.get(self).add_all_view(opts).save
        resp = database.get(view_path)
      end
      
      @objects = []
      data = JSON.parse(resp.body)["rows"]
      data.each do |row|
        @objects << RelaxDB.create_from_hash(row["value"])
      end
      @objects
    end

    # TODO: Destroy should presumably destroy all children
    # Destroy semantics in AR are that all callbacks are invoked (as opposed to delete) 
    # Destroy is also used by DM. To destroy all, DM uses e.g. Post.all.destroy! see below
    # http://groups.google.com/group/datamapper/browse_thread/thread/866ead34237f0e7b
    # Returning something other than the http response would be good too
    def destroy!
      RelaxDB::Database.std_db.delete("#{_id}?rev=#{_rev}")
    end

    # TODO: Meh! Use bulk update to do this efficiently
    def self.destroy_all!
      self.all.each do |o| 
        o.destroy!
      end
    end
            
  end
  
  def self.load(id)
    self.load_by_id(id)
  end
    
  def self.load_by_id(id)
    database = RelaxDB::Database.std_db
    resp = database.get("#{id}")
    data = JSON.parse(resp.body)
    create_from_hash(data)
  end
  
  def self.create_from_hash(data)
    # revise use of string 'class' - it's a reserved word in JavaScript
    klass = data.delete("class")
    k = Module.const_get(klass)
    k.new(data)    
  end
  
end