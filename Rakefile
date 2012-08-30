
$: << "lib"

desc "Generate a suite of test certificates"
task :ssl do
  require 'certmaker'
  require 'yaml'

  y = YAML.load_file('config.yml')
  CertMaker.make_certs y
end

desc "Clean up by deleting the 'certs' directory."
task :clean do
  rm_r "certs"
end
