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
