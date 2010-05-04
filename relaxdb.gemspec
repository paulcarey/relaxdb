# Updating the gemspec
#   ruby -e 'Dir["spec/*"].each { |fn| puts "\"#{fn}\," }'

Gem::Specification.new do |s|
  s.name = "relaxdb"
  s.version = "0.5"
  s.date = "2010-04-10"
  s.summary = "RelaxDB provides a simple interface to CouchDB"
  s.email = "paul.p.carey@gmail.com"
  s.homepage = "http://github.com/paulcarey/relaxdb/"
  s.has_rdoc = false
  s.authors = ["Paul Carey"]
  s.files = ["LICENSE",
   "README.textile",
   "readme.rb",
   "Rakefile",
   "docs/spec_results.html",
   "lib/relaxdb",
   "lib/relaxdb/all_delegator.rb",
   "lib/relaxdb/design_doc.rb",
   "lib/relaxdb/document.rb",
   "lib/relaxdb/extlib.rb",
   "lib/relaxdb/net_http_server.rb",
   "lib/relaxdb/migration.rb",
   "lib/relaxdb/migration_version.rb",
   "lib/relaxdb/paginate_params.rb",
   "lib/relaxdb/paginator.rb",
   "lib/relaxdb/query.rb",
   "lib/relaxdb/references_proxy.rb",   
   "lib/relaxdb/relaxdb.rb",
   "lib/relaxdb/server.rb",
   "lib/relaxdb/uuid_generator.rb",
   "lib/relaxdb/taf2_curb_server.rb",
   "lib/relaxdb/validators.rb",
   "lib/relaxdb/view_by_delegator.rb",
   "lib/relaxdb/view_object.rb",
   "lib/relaxdb/view_result.rb",
   "lib/relaxdb/view_uploader.rb",
   "lib/relaxdb/views.rb",
   "lib/more/grapher.rb",
   "lib/relaxdb.rb",
   "spec/callbacks_spec.rb",
   "spec/derived_properties_spec.rb",
   "spec/design_doc_spec.rb",
   "spec/doc_inheritable_spec.rb",
   "spec/document_spec.rb",
   "spec/migration_spec.rb",
   "spec/migration_version_spec.rb",
   "spec/paginate_params_spec.rb",
   "spec/paginate_spec.rb",
   "spec/query_spec.rb",
   "spec/references_proxy_spec.rb",
   "spec/relaxdb_spec.rb",
   "spec/server_spec.rb",
   "spec/spec.opts",
   "spec/spec_helper.rb",
   "spec/spec_models.rb",
   "spec/uuid_generator_spec.rb",
   "spec/view_docs_by_spec.rb",
   "spec/view_object_spec.rb"]
  s.bindir = "bin"
  s.autorequire = "relaxdb"
  s.add_dependency "extlib", "~> 0.9.4"
  s.add_dependency "json", "~> 1.4"
  s.require_paths = ["lib"]
end
