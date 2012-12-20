
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

namespace(:spec) do
  desc "Create rspec code coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].execute
  end
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
        sh 'git clone --branch gh-pages --single-branch `git config remote.origin.url` rdoc'
      rescue
      end
    end
  end
end

require 'certmaker/tasks'

desc "Runs certs:clean"
task :clean => ['certs:clean']
