require 'rubygems'
require 'json'
require 'net/http'
require 'parsedate'
require 'pp'
require 'logger'
require 'tempfile'
require 'merb-extlib'
require 'cache'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'relaxdb/relaxdb'
require 'relaxdb/server'
require 'relaxdb/document'
require 'relaxdb/has_many_proxy'
require 'relaxdb/references_many_proxy'
require 'relaxdb/has_one_proxy'
require 'relaxdb/belongs_to_proxy'
require 'relaxdb/uuid_generator'
require 'relaxdb/views'
require 'relaxdb/query'

module RelaxDB
end
