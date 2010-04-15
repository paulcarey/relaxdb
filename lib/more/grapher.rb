module RelaxDB
  
  #
  # The GraphCreator uses dot to create a graphical model of an entire CouchDB database
  # It probably only makes sense to run it on a database of a limited size
  # The created graphs can be very useful for exploring relationships
  # Run ruby scratch/grapher_demo.rb for an example
  #
  class GraphCreator
    
    def self.create
      system "mkdir -p graphs"
      
      data = JSON.parse(RelaxDB.db.get("_all_docs").body)
      all_ids = data["rows"].map { |r| r["id"] }
      all_ids = all_ids.reject { |id| id =~ /_/ }
      
      dot = "digraph G { \nrankdir=LR;\nnode [shape=record];\n"
      all_ids.each do |id|
        doc = RelaxDB.load(id)
        atts = "#{doc.class}\\l|"
        doc.properties.each do |prop|
          # we don't care about the revision
          next if prop == :_rev 
          
          prop_val = doc.instance_variable_get("@#{prop}".to_sym)
          atts << "#{prop}\\l#{prop_val}|" if prop_val
        end
        atts = atts[0, atts.length-1]
        
        dot << %Q%#{doc._id} [ label ="#{atts}"];\n%
        
        doc.class.references_rels.each do |relationship, opts|
          id = doc.instance_variable_get("@#{relationship}_id".to_sym)
          dot << %Q%#{id} -> #{doc._id} [ label = "#{relationship}"];\n% if id
        end
                  
      end
      dot << "}"
      
      File.open("graphs/data.dot", "w") { |f| f.write(dot) }
      
      system "dot -Tpng -o graphs/all_docs.png graphs/data.dot"
    end
    
  end
  
end
