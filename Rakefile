# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

# Not really planning to be a gem, yet.
#require 'jeweler'
#Jeweler::Tasks.new do |gem|
#  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
#  gem.name = "ssl_client_test"
#  gem.homepage = ""
#  gem.license = "MIT"
#  gem.summary = %Q{TODO: one-line summary of your gem}
#  gem.description = %Q{TODO: longer description of your gem}
#  gem.email = "bjorvis@isecpartners.com"
#  gem.authors = ["William (B.J.) Snow Orvis"]
#  # dependencies defined in Gemfile
#end
#Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "packetthief #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

$: << "lib"
require 'certmaker/tasks'

desc "Runs certs:clean"
task :clean => ['certs:clean']
