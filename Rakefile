require 'rake'
require 'spec'
require 'spec/rake/spectask'
require 'rake/rdoctask'

desc 'Default: run the specs.'
task :default => :spec

desc 'Run specs for SolrQuery'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc 'Generate documentation for the solr_query plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SolrQuery'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require "rubygems"
require "rake/gempackagetask"

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|

  # Change these as appropriate
  s.name              = "solr_query"
  s.version           = "1.0.2"
  s.description       = "Build SOLR queries, properly escaped, with a nice API"
  s.summary           = "a ruby library designed to make building nested Solr queries simple and standardized. "
  s.author            = "Matthew Rudy Jacobs"
  s.email             = "matthewrudyjacobs@gmail.com"
  s.homepage          = "http://github.com/matthewrudy/solr_query"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README)
  s.rdoc_options      = %w(--main README)

  # Add any extra files to include in the gem
  s.files             = %w(MIT-LICENSE Rakefile README) + Dir.glob("{spec,lib/**/*}")
  s.require_paths     = ["lib"]

  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  # s.add_dependency("some_other_gem", "~> 0.1.0")

  # If your tests use any gems, include them here
  s.add_development_dependency("rspec")
end

# This task actually builds the gem. We also regenerate a static
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
#
# To publish your gem online, install the 'gemcutter' gem; Read more 
# about that here: http://gemcutter.org/pages/gem_docs
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec

  # Generate the gemspec file for github.
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

