module SSLTest

  # TestListener is the real workhorse used by SSLTestCases. It builds on the
  # SSLSmartProxy from PacketThief in order to intercept and forward SSL
  # connections. It uses SSLSmartProxy because SSLSmartProxy provides a default
  # behavior where it grabs the remote certificate from the destination and
  # re-signs it before presenting it to the client.
  #
  # TestListener expands on this by presenting the configured test chain
  # instead of the re-signed remote certificate when the destination
  # corresponds to the hostname the test suite is testing off of.
  class TestListener < PacketThief::Handlers::SSLSmartProxy

    # For all hosts that do not match _hosttotest_, we currently use the
    # _cacert_ and re-sign the original cert provided by the actual host. This
    # will cause issues with certificate revocation.
    #
    # * _cacert_  [OpenSSL::X509::Certificate] A CA that the client should
    #   trust.
    # * _cakey_   [OpenSSL::PKey::PKey] The CA's key, needed for resigning. It
    #   will also be the key used by the resigned certificates.
    # * _hosttotest_  [String] The hostname we want to apply the test chain to.
    # * _chaintotest_ [Array<OpenSSL::X509Certificate>] A chain of certs to
    #   present when the client attempts to connect to hostname.
    # * _keytotest_   [OpenSSL::PKey::PKey] The key corresponding to the leaf
    #   node in _chaintotest_.
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

    # Checks whether the initial original destination certificate (without SNI
    # hostname) matches the test hostname. We do this with post_init to have
    # the check happen after the parent class already added a re-signed
    # certificate to +@ctx+.
    def post_init
      puts "Connection received"
      check_for_hosttotest(@ctx)
    end

    # Checks whether the original destination certificate after we handle the
    # SNI hostname matches the test hostname. Super already replaced the
    # context with a certificate based on the remote host's certificate.
    def servername_cb(sslsock, hostname)
      check_for_hosttotest(super(sslsock, hostname))
    end

    # Replaces the certificates used in the SSLContext with the test
    # certificates if the destination matches the hostname we wish to test
    # against. Otherwise, it leaves the context alone.
    #
    # Additionally, if it matches, it sets @testing_host to true to check
    # whether the test succeeds or not.
    def check_for_hosttotest(actx)
      if TestListener.cert_matches_host(actx.cert, @hosttotest)
        actx.cert = @hostcert
        actx.key = @hostkey
        actx.extra_chain_cert = @extrachain
        @testing_host = true
      end
      actx
    end

    # Return true if _cert_'s CNAME or subjectAltName matches hostname,
    # otherwise return false.
    def self.cert_matches_host(cert, hostname)
      OpenSSL::SSL.verify_certificate_identity(cert, hostname)
    end

    # If the client completes connecting, then they trusted our cert chain.
    def tls_successful_handshake
      super
      puts "successful handshake"
      if @testing_host
        @test_status = :connected
      end
    end

    # If the handshake failed, then we believe the client rejected our cert
    # chain.
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

    # Report our result.
    def unbind
      super
      puts "unbind"
      if @testing_host
        @test_completed_cb.call(@test_status) if @test_completed_cb
      end
    end

  end
end
