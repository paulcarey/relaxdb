# Represents an individual view in CouchDB and a query that may be made against that view
# View name determined by sort attributes
# Query not necessarily a great name if the view name is always all_by... e.g. QueryAll?
# This class performs no error checking 
# Would be nice to have the writers return self so calls can be chained => q.startkey=(foo).endkey=(bar).count=2
class Query
  
  attr_writer :key, :startkey, :endkey, :count, :desc 
  
  def initialize(class_name, *atts)
    @class_name = class_name
    @atts = atts
  end
    
  def view_name
    name = "all_by"

    @atts.each do |att|
      name += "_#{att}_and"
    end
    name[0, name.size-4]
  end
  
  def view_path
    uri = "_view/#{@class_name}/#{view_name}"

    # Scope for factoring this into a loop, but maybe it's as clear like this
    query = ""
    query << "&key=#{@key.to_json}" if @key
    query << "&startkey=#{@startkey.to_json}" if @startkey
    query << "&endkey=#{@endkey.to_json}" if @endkey
    query << "&count=#{@count.to_json}" if @count
    query << "&descending=true" if @desc
    
    uri << query.sub(/^&/, "?")
  end
  
  def map_function
    # To guard against non existing attributes in older documents, an OR check could be inserted
    # in the emit, e.g. emit([doc.certain, (doc.unsure||null)], doc);
    
    # Create the key to be emitted from the attributes, wrapping it in [] if the key is composite
    raw = @atts.inject("") { |m,v| m << "doc.#{v}, " }
    refined = raw[0, raw.size-2]
    pure = @atts.size > 1 ? refined.sub(/^/, "[").sub(/$/, "]") : refined
    
    <<-QUERY
    function(doc) {
      if(doc.class == "#{@class_name}") {
        emit(#{pure}, doc);
      }
    }
    QUERY
  end
      
end
