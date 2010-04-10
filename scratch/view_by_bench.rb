require 'benchmark'

$:.unshift(File.dirname(__FILE__) + "/../lib")
require 'relaxdb'
require File.dirname(__FILE__) + "/../spec/spec_models"

RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"

RelaxDB.delete_db "relaxdb_spec" rescue :ok
RelaxDB.use_db "relaxdb_spec"
RelaxDB.replicate_db "relaxdb_spec_base", "relaxdb_spec"


docs = (1..100).map { |i| Primitives.new :_id => "id#{i}", :str => i.to_s }
RelaxDB.bulk_save! *docs

count = 100

Benchmark.bm do |x|
  
  # Before a delegator existed
  # x.report("simple") do
  #   count.times do
  #     doc_ids = Primitives.by_str
  #     RelaxDB.load! doc_ids
  #   end
  # end 
  
  x.report("delegator") do
    count.times do
      docs = Primitives.by_str.load!
    end
  end 
  
end

# for 1000 docs and count = 100
#      user     system      total        real
# simple 131.520000   2.930000 134.450000 (174.333752)

# for 100 docs and count = 1000
#      user     system      total        real
# simple 121.880000   3.470000 125.350000 (161.864292)

#
# Take Ruby out of the equation and we get...
#
# time for i in {1..100}
# do
#   curl -s 'localhost:5984/relaxdb_spec/_design/spec_doc/_view/Primitives_by_str?reduce=false' > /dev/null
#   curl -s -X POST 'localhost:5984/relaxdb_spec/_all_docs?include_docs=true' -d '{"keys":["id1","id2","id3","id4","id5","id6","id7","id8","id9","id10","id11","id12","id13","id14","id15","id16","id17","id18","id19","id20","id21","id22","id23","id24","id25","id26","id27","id28","id29","id30","id31","id32","id33","id34","id35","id36","id37","id38","id39","id40","id41","id42","id43","id44","id45","id46","id47","id48","id49","id50","id51","id52","id53","id54","id55","id56","id57","id58","id59","id60","id61","id62","id63","id64","id65","id66","id67","id68","id69","id70","id71","id72","id73","id74","id75","id76","id77","id78","id79","id80","id81","id82","id83","id84","id85","id86","id87","id88","id89","id90","id91","id92","id93","id94","id95","id96","id97","id98","id99","id100"]}' > /dev/null
# done
# 
# for 100 docs and count = 1000 via curl and bash
#
# real  0m6.177s
# user  0m0.618s
# sys 0m1.066s


# for 100 docs and count = 100 
#
#       user     system      total        real
# simple 12.240000   0.350000  12.590000 ( 16.987776)
#
#       user     system      total        real
# delegator 12.300000   0.350000  12.650000 ( 16.810736)

# Conclusion - if a penalty exists for using a delegator, it's minimal
# The simplification offered by a delegator to client code is well worth it
#

# Ruby 1.8.7 with performance improvements
#      user     system      total        real
# delegator  6.450000   0.320000   6.770000 ( 10.544567)

# Ruby 1.9.1 with performance enhancements
#       user     system      total        real
# delegator  6.870000   1.250000   8.120000 ( 11.528884)



