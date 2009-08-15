module RelaxDB

  class NotFound < StandardError; end
  class DocumentNotSaved < StandardError; end
  class UpdateConflict < DocumentNotSaved; end
  class ValidationFailure < DocumentNotSaved; end
  
  @@db = nil
  
  class <<self

    def configure(config)
      @@db = CouchDB.new config
      
      raise "A design_doc must be provided" unless config[:design_doc]
      @dd = config[:design_doc]
    end
    
    # This is a temporary method that helps the transition as RelaxDB moves to a single 
    # design doc per application.
    def dd
      @dd
    end
    
    def enable_view_creation default=true
      @create_views = default
    end
    
    # Set in configuration and consulted by view_by, has_many, has_one, references_many and all
    # Views will be added to CouchDB iff this is true
    def create_views?
      @create_views
    end
  
    def db
      @@db
    end
    
    def logger
      @@db.logger
    end
    
    # Creates the named database if it doesn't already exist
    def use_db(name)
      db.use_db name
    end
    
    def db_exists?(name)
      db.db_exists? name
    end
    
    def db_info
      data = JSON.parse db.get.body
      create_object data
    end
    
    def delete_db(name)
      db.delete_db name
    end
    
    def list_dbs
      db.list_dbs
    end
    
    def replicate_db(source, target)
      db.replicate_db source, target
    end
    
    def bulk_save!(*objs)
      if objs[0].equal? :all_or_nothing
        objs.shift
        all_or_nothing = true
      end
      
      pre_save_success = objs.inject(true) { |s, o| s &= o.pre_save }
      raise ValidationFailure, objs.inspect unless pre_save_success
      
      docs = {}
      objs.each { |o| docs[o._id] = o }
      
      data = { "docs" => objs }
      data[:all_or_nothing] = true if all_or_nothing
      resp = db.post("_bulk_docs", data.to_json )
      data = JSON.parse(resp.body)
  
      conflicted = []
      data.each do |new_rev|
        obj = docs[ new_rev["id"] ]
        if new_rev["rev"]
          obj._rev = new_rev["rev"]
          obj.post_save
        else
          conflicted << obj._id
          obj.conflicted
        end
      end
  
      raise UpdateConflict, conflicted.inspect unless conflicted.empty?
      objs
    end
    
    def bulk_save(*objs)
      begin
        bulk_save!(*objs)
      rescue ValidationFailure, UpdateConflict
        false
      end
    end
    
    def reload(obj)
      load(obj._id)
    end
  
    #
    # Examples:
    #   RelaxDB.load "foo", :conflicts => true
    #   RelaxDB.load "foo", :revs => true
    #   RelaxDB.load ["foo", "bar"]
    #
    def load(ids, atts={})
      # RelaxDB.logger.debug(caller.inject("#{db.name}/#{ids}\n") { |a, i| a += "#{i}\n" })
      
      if ids.is_a? Array
        resp = db.post("_all_docs?include_docs=true", {:keys => ids}.to_json)
        data = JSON.parse(resp.body)
        data["rows"].map { |row| row["doc"] ? create_object(row["doc"]) : nil }
      else
        begin
          qs = atts.map{ |k, v| "#{k}=#{v}" }.join("&")
          qs = atts.empty? ? ids : "#{ids}?#{qs}"
          resp = db.get qs
          data = JSON.parse resp.body
          create_object data
        rescue HTTP_404
          nil
        end
      end
    end
    
    def load!(ids)
      res = load(ids)
      
      raise NotFound, ids if res == nil
      raise NotFound, ids if res.respond_to?(:include?) && res.include?(nil)
      
      res
    end
    
    #
    # CouchDB defaults reduce to true when a reduce func is present.
    # RelaxDB used to indiscriminately set reduce=false, allowing clients to override
    # if desired. However, as of CouchDB 0.10, such behaviour results in 
    #   {"error":"query_parse_error","reason":"Invalid URL parameter `reduce` for map view."} 
    # View https://issues.apache.org/jira/browse/COUCHDB-383#action_12722350
    # 
    # This method is an internal workaround for this change to CouchDB and may
    # be removed if a future change allows for a better solution e.g. map=true 
    # or a _map endpoint
    #
    def rf_view view_name, params
      params[:reduce] = false
      view view_name, params
    end
          
    def view(view_name, params = {})
      q = Query.new(view_name, params)
      
      resp = q.keys ? db.post(q.view_path, q.keys) : db.get(q.view_path)
      hash = JSON.parse(resp.body)
      
      if q.raw then hash
      elsif q.reduce then reduce_result hash
      else ViewResult.new hash
      end      
    end
        
    # Should be invoked on the result of a join view
    # Merges all rows based on merge_key and returns an array of ViewOject
    def merge(data, merge_key)
      merged = {}
      data["rows"].each do |row|
        value = row["value"]
        merged[value[merge_key]] ||= {}
        merged[value[merge_key]].merge!(value)
      end
      
      merged.values.map { |v| ViewObject.create(v) }
    end
        
    def reduce_result(data)
      res = create_from_hash data
      res.size == 0 ? nil :
        res.size == 1 ? res[0] : res
    end
    
    def paginate_view(view_name, atts)      
      page_params = atts.delete :page_params
      view_keys = atts.delete :attributes
      
      paginate_params = PaginateParams.new atts
      raise paginate_params.error_msg if paginate_params.invalid? 
      
      paginator = Paginator.new(paginate_params, page_params)

      atts[:reduce] = false
      query = Query.new(view_name, atts)
      query.merge(paginate_params)
      
      docs = ViewResult.new(JSON.parse(db.get(query.view_path).body))
      docs.reverse! if paginate_params.order_inverted?
      
      paginator.add_next_and_prev(docs, view_name, view_keys)
      
      docs
    end
        
    def create_from_hash(data)
      data["rows"].map { |row| create_object(row["value"]) }
    end
  
    def create_object(data)
      klass = data.is_a?(Hash) && data.delete("relaxdb_class")
      if klass
        k = klass.split("::").inject(Object) { |x, y| x.const_get y }
        k.new data
      else 
        # data is a scalar or not of a known class
        ViewObject.create data
      end
    end
        
    # Convenience methods - should be in a diffent module?
    
    def get(uri=nil)
      JSON.parse(db.get(uri).body)
    end
    
    def pp_get(uri=nil)
      resp = db.get(uri)
      pp(JSON.parse(resp.body))
    end

    def pp_post(uri=nil, json=nil)
      resp = db.post(uri, json)
      pp(JSON.parse(resp.body))
    end
  
  end
  
end
