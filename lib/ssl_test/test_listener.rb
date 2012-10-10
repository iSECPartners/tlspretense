module SSLTest


  class TestListener < PacketThief::Handlers::SSLSmartProxy

    # For all other certificates, we currently use the goodca and re-sign the
    # original cert. This will have issues with certificate revocatation.
    #
    # * *cacert*  [OpenSSL::X509::Certificate] A CA that the client should
    #             trust.
    # * *cakey*   [OpenSSL::PKey::PKey] The CA's key, needed for resigning. It
    #             will also be the key used by the resigned certificates.
    # * *hosttotest*  [String] The hostname we want to apply the test chain to.
    # * *chaintotest* [Array<OpenSSL::X509Certificate>] A chain of certs to
    #                 present when the client attempts to connect to hostname.
    # * *keytotest*   [OpenSSL::PKey::PKey] The key corresponding to the leaf
    #                 node in *chaintotest*.
    def initialize(tcpsocket, cacert, cakey, hosttotest, chaintotest, keytotest)
      puts "initialize"
      @hosttotest = hosttotest
      chain = chaintotest.dup
      @hostcert = chain.shift
      @hostkey = keytotest
      @extrachain = chain
      # Use the goodca for hosts we don't care to test against.
      super(tcpsocket, cacert, cakey)

      @test_status = :running
      @testing_host = false
    end

    # Override to check for the hostname we are testing.
    def post_init
      puts "Connection received"
      check_for_hosttotest(@ctx)
    end

    # Override to check for the hostname we are testing.
    def servername_cb(sslsock, hostname)
      check_for_hosttotest(super(sslsock, hostname))
    end

    # Replaces the leaf certificate if the hostname matches.
    # Also, set @testing_host to true if we match.
    def check_for_hosttotest(actx)
      if TestListener.cert_matches_host(actx.cert, @hosttotest)
        actx.cert = @hostcert
        actx.key = @hostkey
        actx.extra_chain_cert = @extrachain
        @testing_host = true
      end
      actx
    end

    def self.cert_matches_host(cert, hostname)
      OpenSSL::SSL.verify_certificate_identity(cert, hostname)
    end

    # If the client completes connecting, then they trusted our cert.
    def tls_successful_handshake
      super
      puts "successful handshake"
      if @testing_host
        @test_status = :connected
      end
    end

    # If the handshake failed
    def tls_failed_handshake(e)
      super
      puts "failed handshake"
      if @testing_host
        @test_status = :rejected
      end
    end

    def on_test_completed(blk=nil, &block)
      @test_completed_cb = ( blk ? blk : block)
    end

    def unbind
      super
      puts "unbind"
      if @testing_host
        @test_completed_cb.call(@test_status) if @test_completed_cb
      end
    end

  end
end
