require 'rubygems'
require 'rake/gempackagetask'
require 'spec/rake/spectask'

PLUGIN = "relaxdb"
NAME = "relaxdb"
GEM_VERSION = "0.5.3"
AUTHOR = "Paul Carey"
EMAIL = "paul.p.carey@gmail.com"
HOMEPAGE = "http://github.com/paulcarey/relaxdb/"
SUMMARY = "RelaxDB provides a simple interface to CouchDB"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.textile", "LICENSE"]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  
  s.add_dependency "extlib", "~> 0.9.4"
  s.add_dependency "json", "~> 1.4"
  
  s.require_path = 'lib'
  s.autorequire = PLUGIN
  s.files = %w(LICENSE README.textile readme.rb Rakefile) + Dir.glob("{docs,lib,spec}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install"
task :install => [:package] do
  sh %{gem install --no-rdoc --no-ri --local pkg/#{NAME}-#{GEM_VERSION}}
end

desc "Run specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

desc "Run specs and produce spec_results.html"
Spec::Rake::SpecTask.new('spec:html') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.spec_opts = ["--format", "html:docs/spec_results.html"]
end

desc "Create base spec db"
task :create_base_db do
  require 'spec/spec_helper'
  create_base_db
end
