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

    let(:appcontext) { double('appcontext') }
    let(:curr_test) { double('curr_test',
                             :id => 'curr_test',
                             :hosttotest => hosttotest,
                             :certchain => chaintotest,
                             :keychain => [keytotest],
                             :cacert => cacert,
                             :cakey => cakey,
                            ) }
    let(:test_manager) { double('test_manager',
                                :paused? => false,
                                :current_test => curr_test,
                                :test_completed => nil,
                                :testing_method => 'senddata',
                                :goodcacert => double('goodcacert'),
                                :goodcakey => double('goodcakey')
                               ) }

    # Yes this is bad, but there are too many side effects to calling into
    # the parent class right now.
    before(:each) do
#      PacketThief::Handlers::SSLSmartProxy.any_instance.stub(:initialize)
#      PacketThief::Handlers::SSLSmartProxy.any_instance.stub(:tls_successful_handshake)
#      PacketThief::Handlers::SSLSmartProxy.any_instance.stub(:tls_failed_handshake)
#      PacketThief::Handlers::SSLSmartProxy.any_instance.stub(:unbind)
      class PacketThief::Handlers::SSLSmartProxy
        def initialize(socket, certchain, key, logger=nil)
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
      _tcpsocket, _appcontext, _testmanager = tcpsocket, appcontext, test_manager
      TestListener.allocate.instance_eval do
        initialize(_tcpsocket, _testmanager)
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
          @context.cert = double('resigned remote cert', :subject => double('resigned remote cert subject'))
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
          @remotecert = double('resigned remote cert', :subject => double('resigned remote cert subject'))
          @context.cert = @remotecert
          @context.key = cakey
          @context.extra_chain_cert = [cacert]

          @newcontext = subject.check_for_hosttotest(@context)

          @newcontext.cert.should == @remotecert
          @newcontext.key.should == cakey
          @newcontext.extra_chain_cert.should == [cacert]
        end
      end

      context "when the test manager reports that testing is paused" do
        before(:each) do
          test_manager.stub(:paused?).and_return(true)
        end

        it "returns an unchanged context" do
          @context = OpenSSL::SSL::SSLContext.new
          @remotecert = double('resigned remote cert', :subject => double('resigned remote cert subject'))
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
      context "when a test listener's connection is to the host to test" do
        before(:each) do
          TestListener.stub(:cert_matches_host).and_return(true)
          @ctx = OpenSSL::SSL::SSLContext.new
          @ctx.cert = double('dest cert', :subject => double('dest cert subject'))
          subject.check_for_hosttotest(@ctx)
        end
        context "when the client connects" do
          before(:each) do
            subject.tls_successful_handshake
          end

          it "calls the test_manager's test_completed callback with :connected when the connection closes" do
            test_manager.should_receive(:test_completed).with(test_manager.current_test, :connected)

            subject.unbind
          end
        end
        context "when the client rejects" do
          it "calls the test_manager's test_completed callback with :rejected" do
            test_manager.should_receive(:test_completed).with(test_manager.current_test, :rejected)

            subject.tls_failed_handshake(double('error'))
          end
        end
        context "when the client sends data" do
          context "when the testing_method is 'senddata'" do
            before(:each) do
              test_manager.stub(:testing_method).and_return('senddata')
            end
            it "client_recv calls the test_manager's test_completed callback with :sentdata" do
              subject.stub(:send_to_dest)

              test_manager.should_receive(:test_completed).with(test_manager.current_test, :sentdata)

              subject.client_recv(double('data'))
            end
          end
        end

      end
    end

  end
end
