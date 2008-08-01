module RelaxDB
    
  def self.bulk_save(*objs)
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
  
  def self.load(id)
    self.load_by_id(id)
  end
    
  def self.load_by_id(id)
    database = RelaxDB.db
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