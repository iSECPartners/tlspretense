require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

module TLSPretense
  module CertMaker
    describe SubjectAltNameFactory do

      describe "the created extension" do
        subject { SubjectAltNameFactory.new.create_san_with_dns(arg) }

        context "when created with www.isecpartners.com" do
          let(:arg) { 'www.isecpartners.com' }
          it "is a subjectAltName Extension" do
            subject.oid.should == 'subjectAltName'
          end
          it "its der encoding contains www.isecpartners.com" do
            subject.to_der.should match /www\.isecpartners\.com/
          end
        end

        context 'when passed "www.isecpartners.com\0foo.com"' do
          let(:arg) { "www.isecpartners.com\0foo.com" }
          it 'its der encoding contains www.isecpartners.com\0foo.com' do
            subject.to_der.should match /www\.isecpartners\.com\0foo\.com/
          end
        end
      end

      describe "the created extension" do
        subject { SubjectAltNameFactory.new.create_san_ext(arg) }

        context 'when the descriptor is "subjectAltName=DNS:www.isecpartners.com"' do
          let(:arg) { "subjectAltName=DNS:www.isecpartners.com" }
          it "the oid is 'subjectAltName'" do
            subject.oid.should == 'subjectAltName'
          end
          it "the der encoding contains www.isecpartners.com" do
            subject.to_der.should match /www\.isecpartners\.com/
          end
        end

        context 'when the descriptor is "subjectAltName=DNS:www.isecpartners.com, DNS:foo.com"' do
          let(:arg) { "subjectAltName=DNS:www.isecpartners.com, DNS:foo.com" }
          it "the der encoding contains www.isecpartners.com" do
            subject.to_der.should match /www\.isecpartners\.com/
          end
          it "the der encoding contains foo.com" do
            subject.to_der.should match /foo\.com/
          end
        end

        context 'when the descriptor is "subjectAltName=DNS:www.isecpartners.com\foo.com, DNS:bar.com"' do
          let(:arg) { "subjectAltName=DNS:www.isecpartners.com\0foo.com, DNS:bar.com" }
          it "the der encoding contains www.isecpartners.com" do
            subject.to_der.should match /www\.isecpartners\.com\0foo\.com/
          end
          it "the der encoding contains bar.com" do
            subject.to_der.should match /bar\.com/
          end
        end

      end

    end
  end
end
