module RelaxDB
  
  @@db = nil
  
  class <<self

    def configure(config)
      @@db = CouchDB.new(config)
    end
  
    def db
      @@db
    end
    
    def logger
      @@db.logger
    end
    
    # Creates the named database if it doesn't already exist
    def use_db(name)
      db.use_db(name)
    end
    
    def delete_db(name)
      db.delete_db(name)
    end
    
    def list_dbs
      db.list_dbs
    end
    
    def replicate_db(source, target)
      db.replicate_db source, target
    end
    
    def bulk_save(*objs)
      docs = {}
      objs.each { |o| docs[o._id] = o }
    
      resp = db.post("_bulk_docs", { "docs" => objs }.to_json )
      data = JSON.parse(resp.body)
    
      data["new_revs"].each do |new_rev|
        docs[ new_rev["id"] ]._rev = new_rev["rev"]
      end
    
      data["ok"]
    end
  
    def load(id)
      resp = db.get("#{id}")
      data = JSON.parse(resp.body)
      create_object(data)
    end
    
    # Used internally by RelaxDB
    def retrieve(view_path, design_doc=nil, view_name=nil, map_function=nil)
      begin
        resp = db.get(view_path)
      rescue => e
        DesignDocument.get(design_doc).add_map_view(view_name, map_function).save
        resp = db.get(view_path)
      end
      
      data = JSON.parse(resp.body)
      ViewResult.new(data)
    end
      
    # Requests the given view from CouchDB and returns a hash.
    # This method should typically be wrapped in one of merge, instantiate, or reduce_result.
    def view(design_doc, view_name)
      q = Query.new(design_doc, view_name)
      yield q if block_given?
      
      resp = db.get(q.view_path)
      JSON.parse(resp.body)      
    end
    
    def paginate_view(view_params, design_doc, view_name, *view_keys)
      
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
    
    # Creates RelaxDB::Document objects from the result
    def instantiate(data)
      create_from_hash(data)
    end
    
    # Returns a scalar, an object, or an Array of objects
    def reduce_result(data)
      obj = data["rows"][0] && data["rows"][0]["value"]
      ViewObject.create(obj)      
    end
        
    def create_from_hash(data)
      data["rows"].map { |row| create_object(row["value"]) }
    end
  
    def create_object(data)
      # revise use of string 'class' - it's a reserved word in JavaScript
      klass = data.delete("class")
      if klass
        k = Module.const_get(klass)
        k.new(data)
      else 
        # data is not of a known class
        ViewObject.create(data)
      end
    end
        
    # Convenience methods - should be in a diffent module?
    
    def pp_get(uri=nil)
      resp = db.get(uri)
      pp(JSON.parse(resp.body))
    end
  
  end
  
end
