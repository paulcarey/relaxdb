module RelaxDB
    
  class Document
    
    # Used to store validation messages
    attr_accessor :errors
    
    # Define properties and property methods
    
    def self.property(prop, opts={})
      # Class instance varibles are not inherited, so the default properties must be explicitly listed 
      # Perhaps a better solution exists. Revise. I think extlib contains a solution for this...
      @properties ||= [:_id, :_rev]
      @properties << prop

      define_method(prop) do
        instance_variable_get("@#{prop}".to_sym)        
      end

      define_method("#{prop}=") do |val|
        instance_variable_set("@#{prop}".to_sym, val)
      end
      
      if opts[:default]
        define_method("set_default_#{prop}") do
          default = opts[:default]
          default = default.is_a?(Proc) ? default.call : default
          instance_variable_set("@#{prop}".to_sym, default)
        end
      end
      
      if opts[:validator]
        define_method("validate_#{prop}") do |prop_val|
          opts[:validator].call(prop_val)
        end
      end
      
      if opts[:validation_msg]
        define_method("#{prop}_validation_msg") do
          opts[:validation_msg]
        end
      end
      
    end

    def self.properties
      # Ensure that classes that don't define their own properties still function as CouchDB objects
      @properties ||= [:_id, :_rev]
    end

    def properties
      self.class.properties
    end
    
    # Specifying these properties here (after property method has been defined) 
    # is kinda ugly. Consider a better solution.
    property :_id 
    property :_rev    
    
    def initialize(hash={})
      # The default _id will be overwritten if loaded from CouchDB
      self._id = UuidGenerator.uuid 
      
      @errors = Errors.new

      # Set default properties if this object has not known CouchDB
      unless hash["_rev"]
        properties.each do |prop|
         if methods.include?("set_default_#{prop}")
           send("set_default_#{prop}")
         end
        end
      end
      
      set_attributes(hash)
    end
    
    def set_attributes(data)
      data.each do |key, val|
        # Only set instance variables on creation - object references are resolved on demand

        # If the variable name ends in _at try to convert it to a Time
        if key =~ /_at$/
            val = Time.local(*ParseDate.parsedate(val)) rescue val
        end
        
        # Ignore param keys that don't have a corresponding writer
        # This allows us to comfortably accept a hash containing superflous data 
        # such as a params hash in a controller 
        if methods.include? "#{key}="
          send("#{key}=".to_sym, val)
        end
                
      end
    end  
    
    def inspect
      s = "#<#{self.class}:#{self.object_id}"
      properties.each do |prop|
        prop_val = instance_variable_get("@#{prop}".to_sym)
        s << ", #{prop}: #{prop_val.inspect}" if prop_val
      end
      self.class.belongs_to_rels.each do |relationship|
        id = instance_variable_get("@#{relationship}_id".to_sym)
        s << ", #{relationship}_id: #{id}" if id
      end
      s << ">"
    end
            
    def to_json
      data = {}
      self.class.belongs_to_rels.each do |relationship, opts|
        id = instance_variable_get("@#{relationship}_id".to_sym)
        data["#{relationship}_id"] = id if id
        if opts[:denormalise]
          add_denormalised_data(data, relationship, opts)
        end
      end
      properties.each do |prop|
        prop_val = instance_variable_get("@#{prop}".to_sym)
        data["#{prop}"] = prop_val if prop_val
      end
      data["class"] = self.class.name
      data.to_json      
    end
    
    # quick n' dirty denormalisation - explicit denormalisation will probably become a 
    # permanent fixture of RelaxDB, but quite likely in a different form to this one
    def add_denormalised_data(data, relationship, opts)
      obj = send(relationship)
      if obj
        opts[:denormalise].each do |prop_name|
          val = obj.send(prop_name)
          data["#{relationship}_#{prop_name}"] = val
        end
      end
    end
    
    def save
      return false unless before_save
      return false unless validates?
            
      set_created_at if unsaved? 
      
      resp = RelaxDB.db.put("#{_id}", to_json)
      self._rev = JSON.parse(resp.body)["rev"]

      after_save

      self
    end  
    
    def validates?
      success = true
      properties.each do |prop|
        if methods.include? "validate_#{prop}"
          prop_val = instance_variable_get("@#{prop}")
          success = send("validate_#{prop}", prop_val) rescue false
          unless success
            if methods.include? "#{prop}_validation_msg"
              @errors["#{prop}".to_sym] = send("#{prop}_validation_msg")
            end
          end
        end
      end
      success
    end
        
    # Hmm. Rename... never_saved? newnew?
    def unsaved?
      @_rev.nil?
    end
    alias_method :new_record?, :unsaved?
    
    def to_param
      self._id
    end
    alias_method :id, :to_param
    
    def set_created_at
      if methods.include? "created_at"
        # Don't override it if it's already been set
        @created_at = Time.now if @created_at.nil?
      end
    end
       
    def create_or_get_proxy(klass, relationship, opts=nil)
      proxy_sym = "@proxy_#{relationship}".to_sym
      proxy = instance_variable_get(proxy_sym)
      unless proxy
        proxy = opts ? klass.new(self, relationship, opts) : klass.new(self, relationship)
      end
      instance_variable_set(proxy_sym, proxy)
      proxy     
    end
    
    # Returns true if CouchDB considers other to be the same as self
    def ==(other)
      other && _id == other._id
    end
   
    # Deprecated. This method was experimental and will be removed
    # once multi key GETs are available in CouchDB.
    def self.references_many(relationship, opts={})
      # Treat the representation as a standard property 
      properties << relationship
      
      # Keep track of the relationship so peers can be disassociated on destroy
      @references_many_rels ||= []
      @references_many_rels << relationship
     
      define_method(relationship) do
        array_sym = "@#{relationship}".to_sym
        instance_variable_set(array_sym, []) unless instance_variable_defined? array_sym

        create_or_get_proxy(RelaxDB::ReferencesManyProxy, relationship, opts)
      end
    
      define_method("#{relationship}=") do |val|
        # Sharp edge - do not invoke this method
        instance_variable_set("@#{relationship}".to_sym, val)
      end           
    end
   
    def self.references_many_rels
      # Don't force clients to check its instantiated
      @references_many_rels ||= []
    end
   
    def self.has_many(relationship, opts={})
      @has_many_rels ||= []
      @has_many_rels << relationship
      
      define_method(relationship) do
        create_or_get_proxy(HasManyProxy, relationship, opts)
      end
      
      define_method("#{relationship}=") do
        raise "You may not currently assign to a has_many relationship - may be implemented"
      end      
    end

    def self.has_many_rels
      # Don't force clients to check its instantiated
      @has_many_rels ||= []
    end
            
    def self.has_one(relationship)
      @has_one_rels ||= []
      @has_one_rels << relationship
      
      define_method(relationship) do      
        create_or_get_proxy(HasOneProxy, relationship).target
      end
      
      define_method("#{relationship}=") do |new_target|
        create_or_get_proxy(HasOneProxy, relationship).target = new_target
      end
    end
    
    def self.has_one_rels
      @has_one_rels ||= []      
    end
            
    def self.belongs_to(relationship, opts={})
      @belongs_to_rels ||= {}
      @belongs_to_rels[relationship] = opts

      define_method(relationship) do
        create_or_get_proxy(BelongsToProxy, relationship).target
      end
      
      define_method("#{relationship}=") do |new_target|
        create_or_get_proxy(BelongsToProxy, relationship).target = new_target
      end
      
      # Allows all writers to be invoked from the hash passed to initialize 
      define_method("#{relationship}_id=") do |id|
        instance_variable_set("@#{relationship}_id".to_sym, id)
      end

      # Allows belongs_to relationships to be used by the paginator
      define_method("#{relationship}_id") do
        instance_variable_get("@#{relationship}_id")
      end
      
    end
    
    def self.belongs_to_rels
      # Don't force clients to check that it's instantiated
      @belongs_to_rels ||= {}
    end
    
    def self.all_relationships
      belongs_to_rels + has_one_rels + has_many_rels + references_many_rels
    end
        
    def self.all
      @all_delegator ||= AllDelegator.new(self)      
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
      RelaxDB.db.delete("#{_id}?rev=#{_rev}")
      self
    end
    
    #
    # Callbacks - define these in a module and mix'em'in ?
    #
    def self.before_save(callback)
      before_save_callbacks << callback
    end 
    
    def self.before_save_callbacks
      @before_save ||= []
    end       
    
    def before_save
      self.class.before_save_callbacks.each do |callback|
        resp = callback.is_a?(Proc) ? callback.call(self) : send(callback)
        return false unless resp
      end
    end
    
    def self.after_save(callback)
      after_save_callbacks << callback
    end
    
    def self.after_save_callbacks
      @after_save_callbacks ||= []
    end
    
    def after_save
      self.class.after_save_callbacks.each do |callback|
        callback.is_a?(Proc) ? callback.call(self) : send(callback)
      end
    end
    
    def self.paginate_by(page_params, *atts)
      paginate_params = PaginateParams.new
      yield paginate_params
      raise paginate_params.error_msg if paginate_params.invalid? 
      
      paginator = Paginator.new(paginate_params, page_params)
                  
      doc_view = SortedByView.new(self.name, *atts)
      doc_query = Query.new(self.name, doc_view.view_name)
      doc_query.merge(paginator.paginate_params)
      
      @docs = RelaxDB.retrieve(doc_query.view_path, self, doc_view.view_name, doc_view.map_function)
      @docs.reverse! if paginate_params.order_inverted?
      
      paginator.add_next_and_prev(@docs, self.name, doc_view, atts)
      
      @docs
    end
                
  end
  
end
