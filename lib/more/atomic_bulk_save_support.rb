$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'relaxdb'
require File.dirname(__FILE__) + '/../../spec/spec_models.rb'

RelaxDB.configure :host => "localhost", :port => 5984
RelaxDB.delete_db "relaxdb_spec" rescue :ok
RelaxDB.use_db "relaxdb_spec"

a1 = Atom.new.save!
a1_dup = a1.dup
a1.save!
begin
  RelaxDB.bulk_save! a1_dup
  puts "Atomic bulk_save _not_ supported"
rescue RelaxDB::UpdateConflict
  puts "Atomic bulk_save supported"
end
  