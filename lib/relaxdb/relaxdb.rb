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
      # Ensure that classes that don't define properties still function as CouchDB objects
      @properties ||= [:_id, :_rev]
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
        s << ", #{prop}: #{prop_val.inspect}" if prop_val
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
      # TODO: Revise - loading a parent just so the child can be saved is as bright as muck
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
   
   def references_many_proxy(rel_name, opts=nil)
     array_sym = "@#{rel_name}".to_sym
     instance_variable_set(array_sym, []) unless instance_variable_defined? array_sym
     
     proxy_sym = "@proxy_#{rel_name}".to_sym
     proxy = instance_variable_get(proxy_sym)
     proxy ||= ReferencesManyProxy.new(self, rel_name, opts)
     instance_variable_set(proxy_sym, proxy)
     proxy
   end
   
   def self.references_many(relationship, opts={})
     # Treat the representation as a standard property 
     properties << relationship
     # Keep track of the relationship so peers can be disassociated on destroy
     @references_many_rels ||= []
     @references_many_rels << relationship
     
     define_method(relationship) do
       references_many_proxy(relationship, opts)
     end
    
     define_method("#{relationship}=") do
       raise "You may not currently assign to a has_many relationship - may be implemented"
     end           
   end
   
    def self.has_many(relationship, opts={})
      @has_many_rels ||= []
      @has_many_rels << relationship
      
      define_method(relationship) do
        has_many_proxy(relationship, opts)
      end
      
      define_method("#{relationship}=") do
        raise "You may not currently assign to a has_many relationship - may be implemented"
      end      
    end

    def self.has_many_rels
      # Don't force clients to check its instantiated
      @has_many_rels ||= []
    end
        
    def self.references_many_rels
      # Don't force clients to check its instantiated
      @references_many_rels ||= []
    end
        
    # has_one methods

    def has_one_proxy(rel_name)
      proxy_sym = "@proxy_#{rel_name}".to_sym
      proxy = instance_variable_get(proxy_sym)
      proxy ||= HasOneProxy.new(self, rel_name)
      instance_variable_set(proxy_sym, proxy)
      proxy
    end
    
    def self.has_one(relationship, opts=nil)
      @has_one_rels ||= []
      @has_one_rels << relationship
      
      define_method(relationship) do        
        has_one_proxy(relationship).target
      end
      
      define_method("#{relationship}=") do |new_target|
        has_one_proxy(relationship).target = new_target
      end
    end
    
    def self.has_one_rels
      @has_one_rels ||= []      
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

    # destroy! nullifies all relationships with peers and children before deleting 
    # itself in CouchDB
    # The nullification and deletion are not performed in a transaction
    def destroy!
      self.class.references_many_rels.each do |rel|
        send(rel).clear
      end
      
      self.class.has_many_rels.each do |rel|
        send(rel).clear
      end
      
      self.class.has_one_rels.each do |rel|
        send("#{rel}=".to_sym, nil)
      end
      
      # Implicitly prevent the object from being resaved by failing to update its revision
      RelaxDB::Database.std_db.delete("#{_id}?rev=#{_rev}")
    end

    # Leaves the corresponding DesignDoc for this class intact. Should it? No it shouldn't!
    def self.destroy_all!
      self.all.each do |o| 
        o.destroy!
      end
    end
            
  end
  
  def self.bulk_save(*objs)
    docs = {}
    objs.each { |o| docs[o._id] = o }
    
    database = RelaxDB::Database.std_db
    resp = database.post("_bulk_docs", { "docs" => objs }.to_json )
    data = JSON.parse(resp.body)
    
    data["new_revs"].each do |new_rev|
      docs[ new_rev["id"] ]._rev = new_rev["rev"]
    end
    
    data["ok"]
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