module RelaxDB
    
  class Document
    
    TIME_REGEXP = /_at$|_on$|_date$|_time$/ 
    
    include RelaxDB::Validators
    
    # Used to store validation messages
    attr_accessor :errors
    
    # A call issued to save_all will save this object and the
    # contents of the save_list. This allows secondary object to
    # be saved at the same time as this object.
    attr_accessor :save_list
    
    # Attribute symbols added to this list won't be validated on save
    attr_accessor :validation_skip_list
    
    class_inheritable_accessor :properties, :reader => true
    self.properties = []

    class_inheritable_accessor :derived_prop_writers
    self.derived_prop_writers = {}
    
    class_inheritable_accessor :__view_docs_by_list__
    self.__view_docs_by_list__ = []
    
    class_inheritable_accessor :__view_by_list__
    self.__view_by_list__ = []    
    
    class_inheritable_accessor :belongs_to_rels, :reader => true
    self.belongs_to_rels = {}
            
    def self.property(prop, opts={})
      properties << prop

      define_method(prop) do
        instance_variable_get("@#{prop}".to_sym)        
      end

      define_method("#{prop}=") do |val|
        instance_variable_set("@#{prop}".to_sym, val)
      end
      
      if opts[:default]
        define_method("__set_default_#{prop}__") do
          default = opts[:default]
          default = default.is_a?(Proc) ? default.call : default
          instance_variable_set("@#{prop}".to_sym, default)
        end
      end
      
      if opts[:validator]
        create_validator(prop, opts[:validator]) 
      end
      
      if opts[:validation_msg]
        create_validation_msg(prop, opts[:validation_msg])
      end
      
      if opts[:derived]
        add_derived_prop(prop, opts[:derived])
      end
    end    
  
    property :_id 
    property :_rev        
    property :_conflicts        
    
    def self.create_validator(att, v)
      method_name = "validate_#{att}"
      if v.is_a? Proc
        v.arity == 1 ?
          define_method(method_name) { |att_val| v.call(att_val) } :
          define_method(method_name) { |att_val| v.call(att_val, self) }
      else
        v_meths = instance_methods.select { |m| m =~ /validator_/ }
        v_meths.map! { |m| m.to_sym } if RUBY_VERSION.to_f < 1.9
        if v_meths.include? "validator_#{v}".to_sym
          define_method(method_name) { |att_val| send("validator_#{v}", att_val, self) }
        else
          define_method(method_name) { |att_val| send(v, att_val) }
        end          
      end
    end
    
    def self.create_validation_msg(att, validation_msg)
      if validation_msg.is_a?(Proc)        
        validation_msg.arity == 1 ?
          define_method("#{att}_validation_msg") { |att_val| validation_msg.call(att_val) } :
          define_method("#{att}_validation_msg") { |att_val| validation_msg.call(att_val, self) } 
      else  
        define_method("#{att}_validation_msg") { |att_val| validation_msg } 
      end
    end
    
    # See derived_properties_spec.rb for usage
    def self.add_derived_prop(prop, deriver)
        source, writer = deriver[0], deriver[1]
        derived_prop_writers[source] ||= {}
        derived_prop_writers[source][prop] = writer
    end
        
    #
    # The rationale for rescuing the send below is that the lambda for a derived 
    # property shouldn't need to concern itself with checking the validity of
    # the underlying property. Nor, IMO, should clients be exposed to the 
    # possibility of a writer raising an exception.
    #
    def write_derived_props(source)
      writers = self.class.derived_prop_writers
      writers = writers && writers[source]
      if writers 
        writers.each do |prop, writer|
          current_val = send(prop)
          begin
            send("#{prop}=", writer.call(current_val, self)) 
          rescue => e
            RelaxDB.logger.error "Deriving #{prop} from #{source} raised #{e}"
          end
        end
      end
    end
    
    def initialize(hash={})
      unless hash["_id"]
        self._id = UuidGenerator.uuid 
      end
      
      @errors = Errors.new
      @save_list = []
      @validation_skip_list = []
      
      # Set default properties if this object isn't being loaded from CouchDB
      unless hash["_rev"]
        default_methods = methods.select { |m| m =~ /__set_default/ }
        default_methods.map! { |m| m.to_sym } if RUBY_VERSION.to_f < 1.9
        properties.each do |prop|
         if default_methods.include? "__set_default_#{prop}__".to_sym
           send("__set_default_#{prop}__")
         end
        end
      end
            
      @set_derived_props = hash["_rev"] ? false : true
      set_attributes(hash)
      @set_derived_props = true
    end
    
    def set_attributes(data)
      data.each do |key, val|
        # Only set instance variables on creation - object references are resolved on demand

        # If the variable name ends in _at, _on or _date try to convert it to a Time
        if TIME_REGEXP =~ key
          val = Time.parse(val).utc rescue val
        end
        
        if @set_derived_props
          send("#{key}=".to_sym, val)
        else
          instance_variable_set("@#{key}", val)
        end     
      end
    end  
            
    def inspect
      s = "#<#{self.class}:#{self.object_id}"
      properties.each do |prop|
        prop_val = instance_variable_get("@#{prop}".to_sym)
        s << ", #{prop}: #{prop_val.inspect}" if prop_val
      end
      self.class.belongs_to_rels.each do |relationship, opts|
        id = instance_variable_get("@#{relationship}_id".to_sym)
        s << ", #{relationship}_id: #{id}" if id
      end
      s << ", errors: #{errors.inspect}" unless errors.empty?
      s << ", save_list: #{save_list.map { |o| o.inspect }.join ", " }" unless save_list.empty?
      s << ">"
    end
    
    alias_method :to_s, :inspect
            
    def to_json
      data = {}
      self.class.belongs_to_rels.each do |relationship, opts|
        id = instance_variable_get("@#{relationship}_id".to_sym)
        data["#{relationship}_id"] = id if id
      end
      properties.each do |prop|
        prop_val = instance_variable_get("@#{prop}".to_sym)
        data["#{prop}"] = prop_val if prop_val
      end
      data["errors"] = errors unless errors.empty?
      data["relaxdb_class"] = self.class.name
      data.to_json      
    end
            
    # Not yet sure of final implemention for hooks - may lean more towards DM than AR
    def save
      if pre_save && save_to_couch
        after_save
        self
      else
        false
      end
    end  
    
    def save_to_couch
      begin
        resp = RelaxDB.db.put(_id, to_json)
        self._rev = JSON.parse(resp.body)["rev"]
      rescue HTTP_409
        conflicted
        return false
      end      
    end
    
    def conflicted
      @update_conflict = true
      on_update_conflict
    end    
    
    def on_update_conflict
      # override with any behaviour you want to happen when
      # CouchDB returns DocumentConflict on an attempt to save
    end
    
    def update_conflict?
      @update_conflict
    end    
    
    def pre_save
      set_timestamps
      return false unless validates?
      return false unless before_save            
      true 
    end  
    
    def post_save
      after_save
    end
    
    # save_all and save_all! are untested
    def save_all
      RelaxDB.bulk_save self, *save_list
    end
    
    def save_all!
      RelaxDB.bulk_save! self, *save_list
    end
    
    def save!
      if save
        self
      elsif update_conflict?
        raise UpdateConflict, self
      else
        raise ValidationFailure, self.errors.to_json
      end
    end
            
    def validates?
      props = properties - validation_skip_list
      prop_vals = props.map { |prop| instance_variable_get("@#{prop}") }
      
      rels = self.class.belongs_to_rels.keys - validation_skip_list
      rel_vals = rels.map { |rel| instance_variable_get("@#{rel}_id") }
      
      att_names = props + rels
      att_vals =  prop_vals + rel_vals
      
      total_success = true
      validate_methods = methods.select { |m| m =~ /validate_/ }
      validate_methods.map! { |m| m.to_sym } if RUBY_VERSION.to_f < 1.9
      att_names.each_index do |i|
        att_name, att_val = att_names[i], att_vals[i]
        if validate_methods.include? "validate_#{att_name}".to_sym
          total_success &= validate_att(att_name, att_val)
        end
      end
            
      total_success
    end
    alias_method :validate, :validates?
    
    def validate_att(att_name, att_val)
      begin
        success = send("validate_#{att_name}", att_val)
      rescue => e
        RelaxDB.logger.warn "Validating #{att_name} with #{att_val} raised #{e}"
        succes = false
      end

      unless success
        v_msg_meths = methods.select { |m | m =~ /_validation_msg/ }
        v_msg_meths.map! { |m| m.to_sym } if RUBY_VERSION.to_f < 1.9
        if v_msg_meths.include? "#{att_name}_validation_msg".to_sym
          begin
            @errors[att_name] = send("#{att_name}_validation_msg", att_val)
          rescue => e
            puts "#{e.backtrace[0, 5].join("\n")}"
            RelaxDB.logger.warn "Validation_msg for #{att_name} with #{att_val} raised #{e}"
            @errors[att_name] = "validation_msg_exception:invalid:#{att_val}"
          end
        elsif @errors[att_name].nil?
          # Only set a validation message if a validator hasn't already set one
          @errors[att_name] = "invalid:#{att_val}"
        end
      end
      success
    end
            
    def new_document?
      @_rev.nil?
    end
    alias_method :new_record?, :new_document?
    alias_method :unsaved?, :new_document?
    
    def to_param
      self._id
    end
    alias_method :id, :to_param
    
    def set_timestamps
      now = Time.now
      if new_document? && respond_to?(:created_at)
        # Don't override it if it's already been set
        @created_at = now if @created_at.nil?
      end
      
      @updated_at = now if respond_to?(:updated_at)
    end
       
    def create_or_get_proxy(klass, relationship, opts=nil)
      proxy_sym = "@proxy_#{relationship}".to_sym
      proxy = instance_variable_get(proxy_sym)
      unless proxy
        proxy = opts ? klass.new(self, relationship, opts) : klass.new(self, relationship)
        instance_variable_set(proxy_sym, proxy)
      end
      proxy     
    end
    
    # Returns true if CouchDB considers other to be the same as self
    def ==(other)
      other && _id == other._id
    end
   
    # If you're using this method, read the specs and make sure you understand
    # how it can be used and how it shouldn't be used
    def self.references_many(relationship, opts={})
      # Treat the representation as a standard property 
      properties << relationship
      
      # Keep track of the relationship so peers can be disassociated on destroy
      @references_many_rels ||= []
      @references_many_rels << relationship
     
      id_arr_sym = "@#{relationship}".to_sym
      
      if RelaxDB.create_views?
        target_class = opts[:class]
        relationship_as_viewed_by_target = opts[:known_as].to_s
        ViewCreator.references_many(self.name, relationship, target_class, relationship_as_viewed_by_target).add_to_design_doc
      end            
     
      define_method(relationship) do
        instance_variable_set(id_arr_sym, []) unless instance_variable_defined? id_arr_sym
        create_or_get_proxy(ReferencesManyProxy, relationship, opts)
      end
      
      define_method("#{relationship}_ids") do
        instance_variable_set(id_arr_sym, []) unless instance_variable_defined? id_arr_sym
        instance_variable_get(id_arr_sym)
      end
    
      define_method("#{relationship}=") do |val|
        # Don't invoke this method unless you know what you're doing
        instance_variable_set(id_arr_sym, val)
      end           
    end
   
    def self.references_many_rels
      @references_many_rels ||= []
    end
   
    def self.has_many(relationship, opts={})
      @has_many_rels ||= []
      @has_many_rels << relationship
      
      if RelaxDB.create_views?
        target_class = opts[:class] || relationship.to_s.singularize.camel_case
        relationship_as_viewed_by_target = (opts[:known_as] || self.name.snake_case).to_s
        ViewCreator.has_n(self.name, relationship, target_class, relationship_as_viewed_by_target).add_to_design_doc
      end      
      
      define_method(relationship) do
        create_or_get_proxy(HasManyProxy, relationship, opts)
      end
      
      define_method("#{relationship}=") do |children|
        create_or_get_proxy(HasManyProxy, relationship, opts).children = children
        write_derived_props(relationship) if @set_derived_props
        children
      end      
    end

    def self.has_many_rels
      # Don't force clients to check its instantiated
      @has_many_rels ||= []
    end
            
    def self.has_one(relationship)
      @has_one_rels ||= []
      @has_one_rels << relationship
      
      if RelaxDB.create_views?
        target_class = relationship.to_s.camel_case      
        relationship_as_viewed_by_target = self.name.snake_case      
        ViewCreator.has_n(self.name, relationship, target_class, relationship_as_viewed_by_target).add_to_design_doc
      end
      
      define_method(relationship) do      
        create_or_get_proxy(HasOneProxy, relationship).target
      end
      
      define_method("#{relationship}=") do |new_target|
        create_or_get_proxy(HasOneProxy, relationship).target = new_target
        write_derived_props(relationship) if @set_derived_props
        new_target
      end
    end
    
    def self.has_one_rels
      @has_one_rels ||= []      
    end
            
    def self.belongs_to(relationship, opts={})
      belongs_to_rels[relationship] = opts

      define_method(relationship) do
        create_or_get_proxy(BelongsToProxy, relationship).target
      end
      
      define_method("#{relationship}=") do |new_target|
        create_or_get_proxy(BelongsToProxy, relationship).target = new_target
        write_derived_props(relationship) if @set_derived_props
      end
      
      # Allows all writers to be invoked from the hash passed to initialize 
      define_method("#{relationship}_id=") do |id|
        instance_variable_set("@#{relationship}_id".to_sym, id)
        write_derived_props(relationship) if @set_derived_props
        id
      end

      define_method("#{relationship}_id") do
        instance_variable_get("@#{relationship}_id")
      end
      
      create_validator(relationship, opts[:validator]) if opts[:validator]
      
      # Untested below
      create_validation_msg(relationship, opts[:validation_msg]) if opts[:validation_msg]
    end
  
    class << self
      alias_method :references, :belongs_to
    end
    
    self.belongs_to_rels = {}
    
    def self.all_relationships
      belongs_to_rels + has_one_rels + has_many_rels + references_many_rels
    end
        
    def self.all params = {}
      AllDelegator.new self.name, params
    end
                    
    # destroy! nullifies all relationships with peers and children before deleting 
    # itself in CouchDB
    # The nullification and deletion are not performed in a transaction
    #
    # TODO: Current implemention may be inappropriate - causing CouchDB to try to JSON
    # encode undefined. Ensure nil is serialized? See has_many_spec#should nullify its child relationships
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
        if resp == false
          errors[:before_save] = :failed
          return false
        end
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
                    
    #
    # Creates the corresponding view, emitting the doc as the val
    # Adds by_ and paginate_by_ methods to the class
    #
    def self.view_docs_by *atts
      opts = atts.last.is_a?(Hash) ? atts.pop : {}
      __view_docs_by_list__ << atts
      
      if RelaxDB.create_views?
        ViewCreator.docs_by_att_list([self.name], *atts).add_to_design_doc
      end
      
      by_name = "by_#{atts.join "_and_"}"
      meta_class.instance_eval do
        define_method by_name do |*params|
          view_name = "#{self.name}_#{by_name}"
          if params.empty?
            RelaxDB.rf_view view_name, opts
          elsif params[0].is_a? Hash
            RelaxDB.rf_view view_name, opts.merge(params[0])
          else
            RelaxDB.rf_view(view_name, :key => params[0]).first
          end            
        end
      end
      
      paginate_by_name = "paginate_by_#{atts.join "_and_"}"
      meta_class.instance_eval do
        define_method paginate_by_name do |params|
          view_name = "#{self.name}_#{by_name}"
          params[:attributes] = atts
          params = opts.merge params
          RelaxDB.paginate_view view_name, params
        end    
      end
    end
    
    
    #
    # Creates the corresponding view, emitting 1 as the val
    # Adds a by_ method to this class, but does not add a 
    # paginate method.
    #
    def self.view_by *atts
      opts = atts.last.is_a?(Hash) ? atts.pop : {}
      opts = opts.merge :raw => true, :reduce => false 
      __view_by_list__ << atts
      
      if RelaxDB.create_views?
        ViewCreator.by_att_list([self.name], *atts).add_to_design_doc
      end
      
      by_name = "by_#{atts.join "_and_"}"
      meta_class.instance_eval do
        define_method by_name do |*params|
          view_name = "#{self.name}_#{by_name}"
          if params.empty?
            ViewByDelegator.new(RelaxDB.doc_ids(view_name, opts))
          elsif params[0].is_a? Hash
            ViewByDelegator.new(RelaxDB.doc_ids(view_name, opts.merge(params[0])))
          else
            ViewByDelegator.new(
              RelaxDB.doc_ids(view_name, opts.merge(:key => params[0]))).load!.first
          end            
        end
      end      
    end
        
    # Create a view allowing all instances of a particular class to be retreived    
    def self.create_all_by_class_view
      ViewCreator.all.add_to_design_doc if RelaxDB.create_views?        
    end          
    
    def self.inherited subclass
      chain = subclass.up_chain
      while k = chain.pop
        k.create_views chain
      end      
    end
    
    def self.up_chain
      k = self
      kls = [k]
      kls << k while ((k = k.superclass) != RelaxDB::Document)
      kls
    end
    
    def self.create_views chain
      # Capture the inheritance hierarchy of this class
      @hierarchy ||= [self]
      @hierarchy += chain
      @hierarchy.uniq!

      if RelaxDB.create_views?
        ViewCreator.all(@hierarchy).add_to_design_doc
        __view_docs_by_list__.each do |atts|
          ViewCreator.docs_by_att_list(@hierarchy, *atts).add_to_design_doc
        end
        
        __view_by_list__.each do |atts|
          ViewCreator.by_att_list(@hierarchy, *atts).add_to_design_doc
        end        
      end
    end
                                            
  end
  
end
