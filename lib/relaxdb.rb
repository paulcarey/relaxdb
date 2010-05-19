require 'rubygems'
require 'extlib'

begin
  require 'yajl'
  require 'yajl/json_gem'
rescue LoadError
  require 'json'
end

require 'cgi'
require 'net/http'
require 'logger'
require 'parsedate' if RUBY_VERSION.to_f < 1.9
require 'pp'
require 'tempfile'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'relaxdb/validators'

begin
  gem 'taf2-curb'
  require 'curb'
  require 'relaxdb/taf2_curb_server'
rescue LoadError
  require 'relaxdb/net_http_server'
end

require 'relaxdb/all_delegator'
require 'relaxdb/design_doc'
require 'relaxdb/document'
require 'relaxdb/extlib'
require 'relaxdb/migration'
require 'relaxdb/paginate_params'
require 'relaxdb/paginator'
require 'relaxdb/query'
require 'relaxdb/references_proxy'
require 'relaxdb/relaxdb'
require 'relaxdb/server'
require 'relaxdb/uuid_generator'
require 'relaxdb/view_by_delegator'
require 'relaxdb/view_object'
require 'relaxdb/view_result'
require 'relaxdb/view_uploader'
require 'relaxdb/views'
require 'more/grapher.rb'

require 'relaxdb/migration_version'

module RelaxDB
end
