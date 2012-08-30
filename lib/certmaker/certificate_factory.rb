module CertMaker
  class CertificateFactory

    attr_accessor :ca, :ca_key
    attr_accessor :subject
    attr_accessor :not_before, :not_after
    attr_accessor :extensions
    attr_accessor :key_type
    attr_accessor :key_size
    attr_accessor :signing_alg

    def initialize
      self.ca = :self
      self.extensions = []
      self.key_type = OpenSSL::PKey::RSA
      self.key_size = 2048
      self.signing_alg = :SHA1
    end

    # Handle special time values.
    #
    # now   Time.now
    # 30    30 days from now
    # -30   30 days before now
    def derive_time(timeval)
      if ['now',:now].include? timeval
        Time.now
      elsif timeval.kind_of? Numeric
        Time.now + timeval*24*60*60
      else
        raise "Unhandled time value: #{timeval}"
      end
    end

    # Returns an array containing the certificate and associated key with the configured attributes, plus with the
    # overridden attrs.
    def create(args={})

      # Make a key
      kt = args.indifferent_fetch(:key_type, self.key_type)
      begin
        kt = OpenSSL::PKey.const_get(kt)
      rescue TypeError
      end
      nk = kt.new self.key_size

      # Certificate basics
      nc = OpenSSL::X509::Certificate.new
      nc.version = 2
      nc.serial = 1
      nc.subject = OpenSSL::X509::Name.parse(args.indifferent_fetch(:subject, self.subject))
      nc.public_key = nk.public_key

      # "now" is a special time value
      nc.not_before = derive_time(args.indifferent_fetch(:not_before,self.not_before))
      nc.not_after = derive_time(args.indifferent_fetch(:not_after,self.not_after))

      # Prep for extensions
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = nc

      self.ca = args.indifferent_fetch(:ca,self.ca)
      # Issuer handling
      if ['self',:self].include? self.ca
        nc.issuer = nc.subject
        ef.issuer_certificate = nc
        signing_key = nk
      else
        nc.issuer = self.ca.subject
        ef.issuer_certificate = self.ca
        signing_key = args.indifferent_fetch(:ca_key,self.ca_key)
      end

      # Copy the extensions (we don't want to modify the original array later)
      exts = args.indifferent_fetch(:extensions, self.extensions).dup
      # filter out blocked extension patterns
      if args.indifferent_fetch(:blockextensions, false)
        args.indifferent_fetch(:blockextensions, nil).each do |badext|
          exts = exts.select { |ext| ext.scan(badext).empty? }
        end
      end
      # add any additional extensions
      exts.concat args.indifferent_fetch(:addextensions,[])

      # Add the extensions
      exts.each do |ext|
        nc.add_extension(ef.create_ext_from_string(ext))
      end

      # Look up the signing algorithm. If it is set to a symbol or string,
      # we'll be able to look up a class. Otherwise we assume that the current
      # signing_alg is a class symbol.
      sa = args.indifferent_fetch(:signing_alg, self.signing_alg)
      begin
        sa = OpenSSL::Digest.const_get(sa)
      rescue TypeError
      end

      nc.sign(signing_key, sa.new)

      return [nc, nk]
    end

  end

end
