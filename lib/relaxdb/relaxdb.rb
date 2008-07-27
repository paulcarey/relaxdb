module RelaxDB
    
  class Document
    
    # Define properties and property methods
    
    def self.property(prop)
      # Class instance varibles are not inherited, so the default properties must be explicitly listed 
      # Perhaps a better solution exists. Revise. I think Merb extlib contains a solution for this...
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

        # If the variable name ends in _at try to convert it to a Time
        if key =~ /_at$/
            val = Time.local(*ParseDate.parsedate(val)) rescue val
        end
        
        instance_variable_set("@#{key}".to_sym, val)
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
      set_created_at_if_new

      resp = RelaxDB::Database.std_db.put("#{_id}", to_json)
      self._rev = JSON.parse(resp.body)["rev"]
      self
    end  
    
    def set_created_at_if_new
      if methods.include? "created_at" and _rev.nil?
        instance_variable_set(:@created_at, Time.now)
      end
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
    
    def self.all
      database = RelaxDB::Database.std_db
        
      view_path = "_view/#{self}/all"
      begin
        resp = database.get(view_path)
      rescue => e
        DesignDocument.get(self).add_all_view.save
        resp = database.get(view_path)
      end
      
      objects_from_view_response(resp.body)
    end
    
    # As method names go, I'm not too enamoured with all_by - Post.all.sort_by might be nice
    def self.all_by(*atts)
      database = RelaxDB::Database.std_db      

      q = Query.new(self.name, *atts)
      yield q if block_given?
      
      puts "RelaxDB submitting query to #{q.view_path}"
      begin
        resp = database.get(q.view_path)
      rescue => e
        DesignDocument.get(self).add_view_to_data(q.view_name, q.map_function).save
        resp = database.get(q.view_path)
      end
      
      objects_from_view_response(resp.body)      
    end
    
    # Should be able to take a query object too
    def self.view(view_name)
      resp = RelaxDB::Database.std_db.get("_view/#{self}/#{view_name}")
      objects_from_view_response(resp.body)
    end
    
    def self.objects_from_view_response(resp_body)
      @objects = []
      data = JSON.parse(resp_body)["rows"]
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
    # Leaves the corresponding DesignDoc for this class intact. Should it? probably...
    def self.destroy_all!
      self.all.each do |o| 
        o.destroy!
      end
    end
            
  end
  
  def self.bulk_save(*objs)
    database = RelaxDB::Database.std_db
    database.post("_bulk_docs", { "docs" => objs }.to_json )
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