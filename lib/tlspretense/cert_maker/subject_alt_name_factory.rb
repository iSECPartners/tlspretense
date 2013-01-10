module TLSPretense
  module CertMaker
    # SubjectAltName, in ASN1, is a sequence comprised of a tag identifying the
    # extension type (subjectAltName, which has objectid tag of 6), and then an
    # octect string that contains an ASN1 encoded sequence of alternative
    # names. Each alternative name is then an ASN1Data with a context-specific
    # tag id. DNS has a tag id of 2, and the string (an IA5String) is just an
    # ascii string (meaning we can have null bytes!)
    #
    #     pp asn1
    #     #<OpenSSL::ASN1::Sequence:0x00000100ac2ca8
    #      @infinite_length=false,
    #      @tag=16,
    #      @tag_class=:UNIVERSAL,
    #      @tagging=nil,
    #      @value=
    #       [#<OpenSSL::ASN1::ObjectId:0x00000100ac2d20
    #         @infinite_length=false,
    #         @tag=6,
    #         @tag_class=:UNIVERSAL,
    #         @tagging=nil,
    #         @value="subjectAltName">,
    #        #<OpenSSL::ASN1::OctetString:0x00000100ac2cd0
    #         @infinite_length=false,
    #         @tag=4,
    #         @tag_class=:UNIVERSAL,
    #         @tagging=nil,
    #         @value="0\x1E\x82\x1Cwww.isecpartners.com\x00foo.com">]>
    #
    #     pp OpenSSL::ASN1.decode(asn1.value[1].value)
    #     #<OpenSSL::ASN1::Sequence:0x00000100ba16d8
    #      @infinite_length=false,
    #      @tag=16,
    #      @tag_class=:UNIVERSAL,
    #      @tagging=nil,
    #      @value=
    #       [#<OpenSSL::ASN1::ASN1Data:0x00000100ba1700
    #         @infinite_length=false,
    #         @tag=2,
    #         @tag_class=:CONTEXT_SPECIFIC,
    #         @value="www.isecpartners.com\x00foo.com">]>
    class SubjectAltNameFactory
      # Creates a subjectAltName extension using a specified dnsname.
      #
      # The purpose here is to bypass the normal OpenSSL subjectAltName
      # constructors because they treat input as a C string at some point,
      # losing everything after a null byte.
      def initialize
        # Lazy-make an existing subjectAltName extension to start from.
        @ef = OpenSSL::X509::ExtensionFactory.new
      end

      def create_san_with_dns(dnsname)
        ext = @ef.create_ext_from_string('subjectAltName=DNS:placeholder')
        ext_asn1 = OpenSSL::ASN1.decode(ext.to_der)
        san_list_der = ext_asn1.value[1].value
        san_list_asn1 = OpenSSL::ASN1.decode(san_list_der)

        san_list_asn1.value[0].value = dnsname

        ext_asn1.value[1].value = san_list_asn1.to_der

        OpenSSL::X509::Extension.new ext_asn1
      end

      # Generates a subjectAltName extension, but with improved null byte
      # support.
      #
      # Desc should look like normal OpenSSL extension description. Eg:
      #
      #     subjectAltName=DNS:foo.com, DNS:bar.com
      #
      # However, if a DNS entry contains a null byte, it doctors the extension
      # to properly include the null byte (Either Ruby's openssl library or
      # something in OpenSSL itself uses a C string at some point, dropping the
      # null byte).
      def create_san_ext(desc)
        hasnullre = /DNS:\s*([^\s]*\0[^\s]*)\s*,/
        matched = hasnullre.match(desc)
        if matched
          nulldomain = matched[1]
          desc = desc.gsub(hasnullre,'DNS:placeholder,')
        end
        ext = @ef.create_ext_from_string(desc)

        if matched
          replace_in_san(ext,'placeholder',nulldomain)
        else
          ext
        end
      end

      def replace_in_san(ext, olddns, newdns)
        ext_asn1 = OpenSSL::ASN1.decode(ext.to_der)
        san_list_der = ext_asn1.value[1].value
        san_list_asn1 = OpenSSL::ASN1.decode(san_list_der)

        san_list_asn1.value.map do |entry|
          if entry.tag == 2 and entry.value == olddns
            entry.value = newdns
          end
          entry
        end

        ext_asn1.value[1].value = san_list_asn1.to_der

        OpenSSL::X509::Extension.new ext_asn1
      end

    end
  end
end
