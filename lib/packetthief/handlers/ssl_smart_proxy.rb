module PacketThief
  module Handlers

    # This SSL proxy needs a CA certificate (or chain) and private key. It then
    # uses that information to automatically generate host certificates. It
    # creates a host certificate by performing a pre-flight request to the
    # original destination to get its certificate. It then doctors that
    # certificate to use a known keypair and the supplied CA.
    #
    # For now, it is lazy with the key, meaning that the supplied key needs to
    # match the CA certificate, but it will also be used as the key for
    # generated certificates.
    class SSLSmartProxy < SSLTransparentProxy

      # How long to wait before giving up on a preflight request. Defaults to 5
      # seconds.
      attr_accessor :preflight_timeout

      def initialize(tcpsocket, ca_chain, key)
        super(tcpsocket)

        @preflight_timeout = 5
        if ca_chain.kind_of? Array
          @ca_chain = ca_chain
        else
          @ca_chain = [ca_chain]
        end
        @key = key

        begin
          # preflight the original destination.
          @ctx.cert = lookup_cert
          @ctx.extra_chain_cert = @ca_chain
          @ctx.key = @key
        rescue OpenSSL::SSL::SSLError, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
          logerror "initialize: Failed to look up cert", :error => e
          close_connection
        end
      end

#      def client_connected
#        # don't try to connect to dest here.
#      end
#

      def servername_cb(sslsock, hostname)
        super
        newctx = sslsock.context.dup
        newctx.cert = lookup_cert(hostname)
        newctx.extra_chain_cert = @ca_chain
        newctx.key = @key
        newctx
      end

      # Requests a certificate from the original destination.
      def preflight_for_cert(hostname=nil)
        logdebug "prefilight for: #{hostname}"
        begin
          pfctx = OpenSSL::SSL::SSLContext.new
          pfctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
          # Try to use a non-blocking Socket to create a short timeout.
          pfs = Socket.new(:AF_INET, :SOCK_STREAM)
          begin
            pfs.connect_nonblock(Socket.sockaddr_in(dest_port, dest_host))
          rescue Errno::EINPROGRESS
            IO.select(nil, [pfs], nil, preflight_timeout) or raise Errno::ETIMEDOUT, "Connection to #{dest_host}:#{dest_port} timed out after #{preflight_timeout} seconds"
          end
          logdebug "preflight tcp socket connected"
          pfssl = OpenSSL::SSL::SSLSocket.new(pfs, pfctx)
          pfssl.hostname = hostname if hostname and pfssl.respond_to? :hostname
          begin
            pfssl.connect_nonblock
          rescue IO::WaitReadable, IO::WaitWritable
            IO.select([pfssl],[pfssl],nil,preflight_timeout) or raise Errno::ETIMEDOUT, "SSL handshake to #{dest_host}:#{dest_port} timed out #{preflight_timeout} seconds"
            retry
          end
          logdebug "preflight complete"
          return pfssl.peer_cert
        rescue OpenSSL::SSL::SSLError, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
          logerror "Error during preflight SSL connection: #{e} (#{e.class})"
          raise
        ensure
          pfssl.close if pfssl
        end
      end


      # Replace the issuer, the public key, and the signature.
      def doctor_cert(oldcert, cacert, key)
        newcert = oldcert.dup
        newcert.issuer = cacert.subject
        newcert.public_key = key.public_key

        exts = newcert.extensions.dup
        exts.each_index do |i|
          if exts[i].oid == "authorityKeyIdentifier"
            ef = OpenSSL::X509::ExtensionFactory.new
            ef.subject_certificate = newcert
            ef.issuer_certificate = cacert
            newe = ef.create_ext_from_string("authorityKeyIdentifier=keyid:always")
            exts[i] = newe
          end
        end
        newcert.extensions = exts

        sigalg = case newcert.signature_algorithm
        when /MD5/i
          OpenSSL::Digest::MD5.new
        when /SHA1/i
          OpenSSL::Digest::SHA1.new
        when /SHA256/i
          OpenSSL::Digest::SHA256.new
        else
          raise "Unsupported signing algorithm: #{@ctx.cert.signing_algorithm}"
        end
        newcert.sign(key, sigalg)
        return newcert
      end

      def lookup_cert(hostname=nil)
        @@certcache ||= {}

        if hostname
          cachekey = "#{hostname}:#{dest_port}"
        else
          cachekey = "#{dest_host}:#{dest_port}"
        end

        return @@certcache[cachekey] if @@certcache.has_key? cachekey
        @@certcache[cachekey] = doctor_cert(preflight_for_cert(hostname), @ca_chain[0], @key)
      end

    end
  end
end
