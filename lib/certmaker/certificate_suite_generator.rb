
module CertMaker
  # Generates a suite of certificates from a configuration.
  #
  # Config should be a hash-like with each key being the alias to a hash-like
  # that describes the certificate. Certificates can then refer to issuers or
  # signing_keys by alias, and CertificateSuiteGenerator will ensure that they
  # are generated in the correct order.
  class CertificateSuiteGenerator
    attr_accessor :certificates

    def initialize(certinfos)
      @certinfos = certinfos
      @certificates = {}
    end

    def certificates
      generate_certificates if @certificates.empty?
      @certificates
    end

    def generate_certificates
      @certinfos.each_pair do |calias, certinfo|
        puts ''
        puts ''
        puts calias
        p certinfo
        generate_certificate(calias, certinfo) unless @certificates.has_key? calias
      end
    end

    def generate_certificate(calias, certinfo)
      puts "Generating #{calias}..."
      cf = CertificateFactory.new

      # configure the issuer
      if certinfo['issuer'] == 'self'
        puts "self signed"
        cf.ca = :self
        cf.ca_key = :self
      else
        issueralias = certinfo['issuer']
        puts "issued by #{issueralias.inspect}"
        raise "Issuer #{issueralias} is not in the list of certificates!" unless @certinfos.has_key? issueralias
        generate_certificate(issueralias,@certinfos[issueralias]) unless @certificates.has_key? issueralias
        ca = @certificates[issueralias]
        cf.ca = ca[:cert]
        cf.ca_key = ca[:key] # Use the issuer's key...
      end
      # ... but override the signing key if it is explicitly specified.
      if certinfo.has_key? 'signing_key'
        signeralias = certinfo['signing_key']
        puts "Signed by #{signeralias.inspect}"
        raise "Signer #{signeralias} is not in the list of certificates!" unless @certinfos.has_key? signeralias
        generate_certificate(signeralias,@certinfos[signeralias]) unless @certificates.has_key? signeralias
        cf.ca_key = @certificates[signeralias][:key]
      end

      cert, key = cf.create(certinfo)
      puts "Created #{calias}"

      @certificates[calias] = { :cert => cert, :key => key }
    end

  end
end
