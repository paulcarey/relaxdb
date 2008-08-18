module RelaxDB
  
  class <<self
    
    def bulk_save(*objs)
      docs = {}
      objs.each { |o| docs[o._id] = o }
    
      database = RelaxDB.db
      resp = database.post("_bulk_docs", { "docs" => objs }.to_json )
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
    
    def retrieve(view_path, design_doc, view_name, map_function)
      begin
        resp = db.get(view_path)
      rescue => e
        DesignDocument.get(design_doc).add_map_view(view_name, map_function).save
        resp = db.get(view_path)
      end
      
      data = JSON.parse(resp.body)
      create_from_view(data)      
    end
  
    def create_from_view(data)
      @objects = []
      data = data["rows"]
      data.each do |row|
        @objects << create_object(row["value"])
      end
      @objects      
    end
  
    def create_object(data)
      # revise use of string 'class' - it's a reserved word in JavaScript
      klass = data.delete("class")
      if klass
        k = Module.const_get(klass)
        k.new(data)
      else 
        # data is not of a known class - it may have been created with a reduce function
        ViewObject.create(data)
      end
    end
    
    # Should be able to take a query object too
    # Allow Documents to call views transparently so underlying invocations don't change
    def view(design_doc, view_name, default_ret_val=[])
      q = Query.new(design_doc, view_name)
      yield q if block_given?
      
      resp = db.get(q.view_path)
      data = JSON.parse(resp.body)

      # presence of total_rows tells us a map function was invoked
      # otherwise a map reduce invocation occured
      if data["total_rows"]
        create_from_view(data)
      else
        obj = data["rows"][0] && data["rows"][0]["value"]
        obj ? create_object(obj) : default_ret_val
      end
    end
      
    def configure(config)
      @@db = CouchDB.new(config)
    end
  
    def db
      @@db
    end
  
    # Convenience methods - should potentially be in a diffent module
  
    def use_scratch
      configure(:host => "localhost", :port => 5984, :db => "scratch", :log_dev => STDOUT, :log_level => Logger::DEBUG)
    end
  
    def get(uri=nil)
      resp = db.get(uri)
      pp(JSON.parse(resp.body))
    end
  
  end
  
end
