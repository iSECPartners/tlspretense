require 'tlspretense/cert_maker'

module TLSPretense
module CertMaker
  class Runner
    include FileUtils

    #Checks for a CA, and generates it if needed.
    def ca
      y = YAML.load_file('config.yml')
      CertMaker.make_ca y
    end

    #Generate a suite of test certificates
    def certs
      ca
      y = YAML.load_file('config.yml')
      CertMaker.make_certs y
    end

    #Clean up by deleting the 'certs' directory.
    def clean
      rm_r "certs"
    end
  end
end
end
