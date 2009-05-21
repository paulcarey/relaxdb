require 'rubygems'
require 'relaxdb'

#
# Purpose of this script is to make it easy to determine which view is 
# causing a "Cannot encode 'undefined' value as JSON" error for a 
# particular doc. Just a quick hack, as such a feature belongs more to 
# CouchDB than a client lib.
#

# Config

src_db = "sd_min"
src_doc_id = "02106105fc50641afe53ff10c70839f7244cbe2b"
src_design_doc = "app20090505165808"

target_db = "scratch"

RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => src_design_doc 

# Load the doc into the target db

RelaxDB.use_db src_db
obj = RelaxDB.get src_doc_id
obj.delete "_rev"
design_doc = RelaxDB.get "_design/#{src_design_doc}"

RelaxDB.delete_db target_db rescue :ok
RelaxDB.use_db target_db
RelaxDB.db.put(obj["_id"], obj.to_json)

# Upload and query a view at a time. The "Cannot encode 'undefined'" error message 
# will appear just prior to the query of the offending view.

dd = RelaxDB::DesignDocument.get src_design_doc
design_doc["views"].each do |view_name, hash|
  map = hash["map"]
  reduce = hash["reduce"]
  dd.add_map_view(view_name, map)
  dd.add_reduce_view(view_name, reduce) if reduce
  dd.save
  
  RelaxDB.get "_design/#{src_design_doc}/_view/#{view_name}"
end
