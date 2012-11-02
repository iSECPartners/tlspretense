require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))
require 'certmaker'

# quick and dirty. just create the fields we need.
def quickcertmaker(hostname, altnames=nil)
  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.subject = OpenSSL::X509::Name.parse("C=US, CN=#{hostname}")
  ef = OpenSSL::X509::ExtensionFactory.new
  ef.subject_certificate = cert
  cert.add_extension(ef.create_ext_from_string("subjectAltName = #{altnames}")) if altnames
  cert
end


module SSLTest
  describe TestListener do
    let(:tcpsocket) { double('tcpsocket') }
    let(:cacert) { double('cacert') }
    let(:cakey) { double('cakey') }
    let(:hosttotest) { double('hosttotest') }
    let(:chaintotest) { [ double('hostcert'), double('intermediatecert'), cacert] }
    let(:keytotest) { double('keytotest') }

    # Yes this is bad, but there are too many side effects to calling into
    # the parent class right now.
    before(:each) do
      class PacketThief::Handlers::SSLSmartProxy
        def initialize(socket, certchain, key)
        end

        def tls_successful_handshake
        end

        def tls_failed_handshake(e)
        end

        def unbind
        end
      end
    end

    subject do
      _tcpsocket, _cacert, _cakey, _hosttotest, _chaintotest, _keytotest = tcpsocket, cacert, cakey, hosttotest, chaintotest, keytotest
      TestListener.allocate.instance_eval do
        initialize(_tcpsocket, _cacert, _cakey, _hosttotest, _chaintotest, _keytotest)
        self
      end
    end


    describe ".cert_matches_host" do
      context "when the CN in the subject is 'my.hostname.com'" do
        let(:cert) { quickcertmaker("my.hostname.com") }

        it {TestListener.cert_matches_host(cert, 'my.hostname.com').should == true}
        it {TestListener.cert_matches_host(cert, 'my.HosTname.Com').should == true}
        it {TestListener.cert_matches_host(cert, 'my2.hostname.com').should == false}

        context "when another.hostname.com is in the subjectAltName" do
          let(:cert) { quickcertmaker("my.hostname.com", "DNS:another.hostname.com, DNS:my.hostname.com") }

          it {TestListener.cert_matches_host(cert, 'my.hostname.com').should == true}
          it {TestListener.cert_matches_host(cert, 'my.HosTname.Com').should == true}
          it {TestListener.cert_matches_host(cert, 'my2.hostname.com').should == false}
          it {TestListener.cert_matches_host(cert, 'another.hostname.com').should == true}
          it {TestListener.cert_matches_host(cert, 'another2.hostname.com').should == false}
        end
      end
    end

    describe "#check_for_hosttotest" do
      context "when the certificate of the destination matches" do
        before(:each) do
          TestListener.stub(:cert_matches_host).and_return(true)
        end

        it "Returns a context where the certificate data matches the hostotest" do
          @context = OpenSSL::SSL::SSLContext.new
          @context.cert = double('resigned remote cert')
          @context.key = cakey
          @context.extra_chain_cert = [cacert]

          @newcontext = subject.check_for_hosttotest(@context)

          @newcontext.cert.should == chaintotest[0]
          @newcontext.key.should == keytotest
          @newcontext.extra_chain_cert.should == chaintotest[1..-1]
        end
      end
      context "when the certificate of the destination does not match" do
        before(:each) do
          TestListener.stub(:cert_matches_host).and_return(false)
        end

        it "Returns an unchanged context" do
          @context = OpenSSL::SSL::SSLContext.new
          @remotecert = double('resigned remote cert')
          @context.cert = @remotecert
          @context.key = cakey
          @context.extra_chain_cert = [cacert]

          @newcontext = subject.check_for_hosttotest(@context)

          @newcontext.cert.should == @remotecert
          @newcontext.key.should == cakey
          @newcontext.extra_chain_cert.should == [cacert]
        end
      end

    end

    describe "reporting the result" do
      context "when a test_completed callback has been set" do
        before(:each) do
          @result = nil
          subject.on_test_completed do |result|
            @result = result
          end
        end
        context "when a test listener's connection is to the host to test" do
          before(:each) do
            TestListener.stub(:cert_matches_host).and_return(true)
            subject.check_for_hosttotest(OpenSSL::SSL::SSLContext.new)
          end
          context "when the client connects" do
            before(:each) do
              subject.tls_successful_handshake
            end

            it "calls the test_completed callback with :connected when the connection closes" do
              subject.unbind

              @result.should == :connected
            end
          end
          context "when the client rejects" do
            before(:each) do
              subject.tls_failed_handshake(double('error'))
            end

            it "calls the test_completed callback with :rejected when the connection closes" do
              subject.unbind

              @result.should == :rejected
            end
          end
          context "when the client sends data" do
            before(:each) do
              subject.stub(:send_to_dest)
              subject.client_recv(double('data'))
            end

            it "calls the test_completed callback with :sentdata when the connection closes" do
              subject.unbind

              @result.should == :sentdata
            end
          end

        end
      end
    end

  end
end
# Screw it, too much to test with super
