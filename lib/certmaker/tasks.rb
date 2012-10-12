
namespace :certs do

  desc "Checks for a CA, and generates it if needed."
  task :ca do
    require 'certmaker'
    require 'yaml'

    y = YAML.load_file('config.yml')
    CertMaker.make_ca y
  end

  desc "Generate a suite of test certificates"
  task :generate => [ 'certs:ca' ] do
    require 'certmaker'
    require 'yaml'

    y = YAML.load_file('config.yml')
    CertMaker.make_certs y
  end

  desc "Clean up by deleting the 'certs' directory."
  task :clean do
    rm_r "certs"
  end
end
