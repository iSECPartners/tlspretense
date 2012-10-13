module PacketThief
  # Some utility methods, currently just used by the examples.
  module Util
    class << self
      # Extracts all PEM encoded certificates out of a raw string and returns
      # each raw PEM encoded certificate in an array.
      def split_chain(raw)
        chain = []
        remaining = raw
        certpat = /-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----/m
        while m = certpat.match(remaining)
          remaining = m.post_match
          chain << m[0].strip
        end
        chain
      end

      # Extracts all PEM encoded certs from a raw string and returns a list of
      # X509 certificate objects in the order they appear in the file.
      #
      # This can be helpful for loading a chain of certificates, eg for a
      # server.
      #
      # Usage:
      #
      #   chain = cert_chain(File.read("chain.pem"))
      #   p chain # => [#<OpenSSL::X509::Certificate subject=/C=US/CN=my.hostname.com, issuer=/C=US/CN=Trusted CA...>,
      #                   #<OpenSSL::X509::Certificate subject=/C=US/CN=Trusted CA ... >]
      def cert_chain(raw)
        rawchain = split_chain(raw)
        rawchain.map { |rawcert| OpenSSL::X509::Certificate.new(rawcert) }
      end

    end
  end
end
