require 'lib/relaxdb' 
require 'spec/spec_models'
RelaxDB.use_scratch

require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = ".irb_history"

IRB.conf[:PROMPT_MODE] = :SIMPLE
