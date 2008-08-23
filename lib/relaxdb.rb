require 'rubygems'
require 'json'
require 'net/http'
require 'parsedate'
require 'pp'
require 'logger'
require 'tempfile'
require 'extlib'
require 'cache'
require 'cgi'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'relaxdb/all_delegator'
require 'relaxdb/belongs_to_proxy'
require 'relaxdb/design_doc'
require 'relaxdb/document'
require 'relaxdb/has_many_proxy'
require 'relaxdb/has_one_proxy'
require 'relaxdb/query'
require 'relaxdb/references_many_proxy'
require 'relaxdb/relaxdb'
require 'relaxdb/server'
require 'relaxdb/sorted_by_view'
require 'relaxdb/uuid_generator'
require 'relaxdb/version'
require 'relaxdb/view_object'
require 'relaxdb/view_uploader'
require 'relaxdb/views'

module RelaxDB
end
