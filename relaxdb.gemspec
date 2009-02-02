Gem::Specification.new do |s|
  s.name = "relaxdb"
  s.version = "0.2.7"
  s.date = "2009-01-18"
  s.summary = "RelaxDB provides a simple interface to CouchDB"
  s.email = "paul.p.carey@gmail.com"
  s.homepage = "http://github.com/paulcarey/relaxdb/"
  s.has_rdoc = false
  s.authors = ["Paul Carey"]
  s.files = ["LICENSE",
   "README.textile",
   "Rakefile",
   "docs/spec_results.html",
   "lib/relaxdb",
   "lib/relaxdb/all_delegator.rb",
   "lib/relaxdb/belongs_to_proxy.rb",
   "lib/relaxdb/design_doc.rb",
   "lib/relaxdb/document.rb",
   "lib/relaxdb/extlib.rb",
   "lib/relaxdb/has_many_proxy.rb",
   "lib/relaxdb/has_one_proxy.rb",
   "lib/relaxdb/paginate_params.rb",
   "lib/relaxdb/paginator.rb",
   "lib/relaxdb/query.rb",
   "lib/relaxdb/references_many_proxy.rb",
   "lib/relaxdb/relaxdb.rb",
   "lib/relaxdb/server.rb",
   "lib/relaxdb/sorted_by_view.rb",
   "lib/relaxdb/uuid_generator.rb",
   "lib/relaxdb/validators.rb",
   "lib/relaxdb/view_object.rb",
   "lib/relaxdb/view_result.rb",
   "lib/relaxdb/view_uploader.rb",
   "lib/relaxdb/views.rb",
   "lib/more/grapher.rb",
   "lib/relaxdb.rb",
   "spec/belongs_to_spec.rb",
   "spec/callbacks_spec.rb",
   "spec/design_doc_spec.rb",
   "spec/derived_properties_spec.rb",
   "spec/document_spec.rb",
   "spec/has_many_spec.rb",
   "spec/has_one_spec.rb",
   "spec/query_spec.rb",
   "spec/references_many_spec.rb",
   "spec/relaxdb_spec.rb",
   "spec/spec.opts",
   "spec/spec_helper.rb",
   "spec/spec_models.rb",
   "spec/view_object_spec.rb"]
  s.bindir = "bin"
  s.autorequire = "relaxdb"
  s.add_dependency "extlib", ">= 0.9.4" # removed ", runtime" as was failing locally
  s.add_dependency "json", ">= 0" # removed ", runtime" as was failing locally
  s.add_dependency "uuid", ">= 0" # removed ", runtime" as was failing locally
  s.require_paths = ["lib"]
end
