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

    describe "#cert_matches_host" do
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
  end
end
# Screw it, too much to test with super
