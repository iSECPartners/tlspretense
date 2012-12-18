module SSLTest
  # Handles the loading and caching of certificates and private keys.
  class CertificateManager

    def initialize(certinfo)
      @certinfo = certinfo
    end

    def get_raw_cert(name)
      File.read(File.join('certs',name+"cert.pem"))
    end

    def get_cert(name)
      OpenSSL::X509::Certificate.new(get_raw_cert(name))
    end

    def get_raw_key(name)
      File.read(File.join('certs',name+"key.pem"))
    end

    def get_key(name)
      OpenSSL::PKey.read(get_raw_key(name))
    end

    def get_chain(list)
      list.map { |name| get_cert(name) }
    end

    def get_keychain(list)
      list.map { |name| get_key(name) }
    end
  end
end
