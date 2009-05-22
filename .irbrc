require 'lib/relaxdb' 

RelaxDB::UuidGenerator.id_length = 4
RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "scratch_dd", :logger => Logger.new(STDOUT)
RelaxDB.use_db "scratch"

# RelaxDB.enable_view_creation # uncomment to create all views
require 'spec/spec_models'

require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = ".irb_history"

IRB.conf[:PROMPT_MODE] = :SIMPLE

def use_spec_db
  RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc", :logger => Logger.new(STDOUT)
  RelaxDB.use_db "relaxdb_spec" 
  RelaxDB.enable_view_creation
end

def new_spec_db
  RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc", :logger => Logger.new(STDOUT)
  RelaxDB.delete_db "relaxdb_spec" rescue "ok"
  RelaxDB.use_db "relaxdb_spec" 
  RelaxDB.replicate_db "relaxdb_spec_base", "relaxdb_spec"
  RelaxDB.enable_view_creation
end

