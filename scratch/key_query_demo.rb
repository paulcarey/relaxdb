# Silence parenthesis warnings with ruby -W0 scratch/keys.rb

#
# A couple of simple illustrations of how keys affect queries
#

$:.unshift(File.dirname(__FILE__) + "/../lib")
require 'relaxdb'
require File.dirname(__FILE__) + "/../spec/spec_models"


RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc", :logger => Logger.new(STDOUT)
class RdbFormatter; def call(sv, time, progname, msg); puts msg; end; end
RelaxDB.logger.formatter = RdbFormatter.new
RelaxDB.delete_db "relaxdb_spec" rescue :ok
RelaxDB.use_db "relaxdb_spec"
RelaxDB.replicate_db "relaxdb_spec_base", "relaxdb_spec"

def p ps
  ps.each { |p| puts("%3s : %3d" % [p._id, p.num]) }
  puts
end

h = {1 => 1, 2 => 2, 3 => 2, 4 => 3, 5 => 3, 6 => 3}
ps = (1..6).map { |i| Primitives.new(:_id => i.to_s, :num => h[i]) }
RelaxDB.bulk_save *ps
puts 

p Primitives.all
p Primitives.by_num
p Primitives.by_num :startkey => 3, :limit => 1
p Primitives.by_num :startkey => 3
p Primitives.by_num :startkey => 3, :startkey_docid => "5"
p Primitives.by_num :startkey_docid => "5"
p Primitives.all :startkey_docid => "2"
p Primitives.all :startkey => "4"