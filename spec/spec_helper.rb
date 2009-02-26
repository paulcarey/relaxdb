begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'relaxdb'

def setup_test_db
  RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"
  
  RelaxDB.delete_db "relaxdb_spec" rescue "ok"
  RelaxDB.use_db "relaxdb_spec"
  begin
    RelaxDB.replicate_db "relaxdb_spec_base", "relaxdb_spec"
  rescue
    puts "Run rake create_base_db before the first spec run"
    exit!
  end
end

def create_base_db
  RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"
  RelaxDB.delete_db "relaxdb_spec_base" rescue "ok"
  RelaxDB.use_db "relaxdb_spec_base"
  require File.dirname(__FILE__) + '/spec_models.rb'
  puts "Created relaxdb_spec_base"
end
