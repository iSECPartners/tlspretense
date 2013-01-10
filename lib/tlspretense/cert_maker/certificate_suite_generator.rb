module TLSPretense
module CertMaker
  # Generates a suite of certificates from a configuration.
  #
  # Config should be a hash-like with each key being the alias to a hash-like
  # that describes the certificate. Certificates can then refer to issuers or
  # signing_keys by alias, and CertificateSuiteGenerator will ensure that they
  # are generated in the correct order.
  class CertificateSuiteGenerator
    attr_accessor :certificates

    # certinfos should be a hash-like where each entry describes a certificate.
    # defaulthostname should be a string that will be inserted into %HOSTNAME%
    # in certificate subject lines.
    def initialize(certinfos, defaulthostname, config={})
      @config = config
      @defaulthostname = defaulthostname
      @parenthostname = defaulthostname.sub(/^[\w-]+\./, '') # remove left-most label
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

      # Check for customgoodca.
      if calias == 'goodca' and @config.has_key? 'customgoodca'
        certfile = @config['customgoodca']['certfile']
        keyfile = @config['customgoodca']['keyfile']
        keypass = @config['customgoodca'].fetch('keypass',nil)
        if File.exist? certfile and File.exist? keyfile
          puts "Customgoodca defined and the CA's files exist. We will use it instead of generating a new goodca."
          rawcert = File.read(certfile)
          rawkey = File.read(keyfile)
          goodcert = OpenSSL::X509::Certificate.new(rawcert)
          goodkey = OpenSSL::PKey.read(rawkey, keypass)
          @certificates[calias] = { :cert => goodcert, :key => goodkey }
          return
        else
          puts "#{certfile} or #{keyfile} does not exist! We will generate a new one."
        end
      end

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
      # doctor the certinfo's subject line and any extensions.
      certinfo['subject'] = replace_tokens(certinfo['subject'])
      if certinfo.has_key? 'extensions'
        certinfo['extensions'] = certinfo['extensions'].map do |ext|
          if ext.kind_of? String
            replace_tokens ext
          else
            ext['value'] = replace_tokens(ext['value'])
            ext
          end
        end
      end
      if certinfo.has_key? 'addextensions'
        certinfo['addextensions'] = certinfo['addextensions'].map do |ext|
          if ext.kind_of? String
            replace_tokens(ext)
          else
            ext['value'] = replace_tokens(ext['value'])
            ext
          end
        end
      end
      # doctor the serial number.
      if @config.has_key? 'missing_serial_generation'
        unless certinfo.has_key? 'serial'
          case @config['missing_serial_generation']
          when "random"
            certinfo['serial'] = randomserial
          else
            certinfo['serial'] = @config['missing_serial_generation']
          end
        end
      end

      cert, key = cf.create(certinfo)
      puts "Created #{calias}"

      @certificates[calias] = { :cert => cert, :key => key }
    end

    def randomserial
      range = 2**30
      begin
        require 'securerandom'
        SecureRandom.random_number range
      rescue LoadError # no securerandom, so use weaker rand.
        rand(range)
      end
    end

    def replace_tokens(str)
        str.gsub(/%HOSTNAME%/, @defaulthostname).gsub(/%PARENTHOSTNAME%/, @parenthostname)
    end

  end
end
end
