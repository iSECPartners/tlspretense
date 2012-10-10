module SSLTest

  # We use the certificate chain and the first key in the keychain from the
  # testcase for the testcase's hosttotest.
  #
  # For all other certificates, we currently use the certificate chain (minus
  # the host cert), and re-sign the original cert. Obviously, this has issues
  # we need to addres.
  class TestListener < PacketThief::Handlers::SSLSmartProxy
    def initialize(tcpsocket, testcase)
      puts "initialize"
      chain = testcase.certchain.dup
      keychain = testcase.keychain.dup
      @testcase = testcase
      @hosttotest = testcase.hosttotest
      @hostcert = chain.shift
      @hostkey = keychain.shift
      # Use the goodca for hosts we don't care to test against.
      super(tcpsocket, testcase.goodcacert, testcase.goodcakey)

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
      return false if actx.cert == nil
      if TestListener.cert_matches_host(actx.cert, @hosttotest)
        actx.cert = @hostcert
        actx.key = @hostkey
        # The extra_chain_certs will already be set by super
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

    def unbind
      super
      puts "unbind"
      if @testing_host
        @testcase.test_completed(@test_status)
      end
    end

  end
end
