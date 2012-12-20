# encoding: utf-8
$: << "lib"
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
  require 'tlspretense/version'
  version = TLSPretense::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.main = 'README.rdoc'
  rdoc.title = "TLSPretense #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('doc/**/*.rdoc')

  rdoc.before_running_rdoc do
    unless File.exist? 'rdoc'
      begin
        sh 'git clone --branch gh-pages --single-branch git@github.com:iSECPartners/tlspretense.git rdoc'
      rescue
      end
    end
  end
end

require 'certmaker/tasks'

desc "Runs certs:clean"
task :clean => ['certs:clean']
