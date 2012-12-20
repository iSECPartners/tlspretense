
namespace :certs do

  desc "Checks for a CA, and generates it if needed."
  task :ca do
    require 'certmaker/runner'
    CertMaker::Runner.new.ca
  end

  desc "Generate a suite of test certificates"
  task :generate => [ 'certs:ca' ] do
    require 'certmaker/runner'
    CertMaker::Runner.new.certs
  end

  desc "Clean up by deleting the 'certs' directory."
  task :clean do
    rm_r "certs"
  end
end
