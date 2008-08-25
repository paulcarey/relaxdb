Gem::Specification.new do |s|
  s.extra_rdoc_files = ["README.textile", "LICENSE"]
  s.date = "Mon Aug 25 00:00:00 +0100 2008"
  s.authors = ["Paul Carey"]
  s.required_rubygems_version = ">= 0"
  s.version = "0.1.0"
  s.files = ["LICENSE",
 "README.textile",
 "Rakefile",
 "docs/spec_results.html",
 "lib/relaxdb",
 "lib/relaxdb/all_delegator.rb",
 "lib/relaxdb/belongs_to_proxy.rb",
 "lib/relaxdb/design_doc.rb",
 "lib/relaxdb/document.rb",
 "lib/relaxdb/has_many_proxy.rb",
 "lib/relaxdb/has_one_proxy.rb",
 "lib/relaxdb/query.rb",
 "lib/relaxdb/references_many_proxy.rb",
 "lib/relaxdb/relaxdb.rb",
 "lib/relaxdb/server.rb",
 "lib/relaxdb/sorted_by_view.rb",
 "lib/relaxdb/uuid_generator.rb",
 "lib/relaxdb/view_object.rb",
 "lib/relaxdb/view_uploader.rb",
 "lib/relaxdb/views.rb",
 "lib/relaxdb.rb",
 "spec/belongs_to_spec.rb",
 "spec/design_doc_spec.rb",
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
  s.has_rdoc = "true"
  s.specification_version = "2"
  s.loaded = "false"
  s.email = "paul.p.carey@gmail.com"
  s.name = "relaxdb"
  s.required_ruby_version = ">= 0"
  s.bindir = "bin"
  s.rubygems_version = "1.2.0"
  s.homepage = "http://github.com/paulcarey/relaxdb/"
  s.platform = "ruby"
  s.autorequire = "relaxdb"
  s.summary = "RelaxDB provides a simple interface to CouchDB"
  s.description = "RelaxDB provides a simple interface to CouchDB"
  s.add_dependency "extlib", ">= 0.9.4" # removed ", runtime" as was failing locally
  s.add_dependency "json", ">= 0" # removed ", runtime" as was failing locally
  s.add_dependency "uuid", ">= 0" # removed ", runtime" as was failing locally
  s.require_paths = ["lib"]
end