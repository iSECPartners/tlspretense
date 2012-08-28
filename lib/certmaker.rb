
require 'fileutils'
require 'yaml'
require 'openssl'

require 'certmaker/run'
require 'certmaker/certificate'
require 'certmaker/certfactory'

module CertMaker

  begin
    CONFIG = YAML.load(File.open('config.yml'))
  rescue
    CONFIG = { 'commonname' => "tickle.me.funny" }
  end

  def run
    include FileUtils

    cd "ssl", :verbose => true

    ca = Certificate.new 'ca', :is_a_ca => true

    c00 = Certificate.new '00-baseline'
    c00.ca = ca
    c00.cert

    c01 = Certificate.new '01-cname_mismatch'
    c01.ca = ca
    c01.cert

    c02 = Certificate.new '02-notwebserver'
    c02.ca = ca
    c02.cert

    c03 = Certificate.new '03-selfsigned'
    c03.ca = ca
    c03.cert

    c04ca = Certificate.new '04ca', :is_a_ca => true
    c04ca.create_cert
    c04 = Certificate.new '04-unknownca'
    c04.ca = c04ca
    c04.cert

    c05intermediate = Certificate.new '05intermediate'
    c05intermediate.ca = ca
    # Signed by an intermediate CA that is not a CA
    c05 = Certificate.new '05-signedbyintermediate'
    c05.ca = c05intermediate
    c05.cert

    c06 = Certificate.new '06-expired', :validity => -30
    c06.ca = ca
    c06.cert

    c07 = Certificate.new '07-md4', :signwith => "md4"
    c07.ca = ca
    c07.cert

    c08 = Certificate.new '08-md5', :signwith => "md5"
    c08.ca = ca
    c08.cert
  end

  def ca_factory
    return @caf if @caf
    @caf = CertificateFactory.new
    @caf.ca = :self
    @caf.subject = "C=US, O=GoatCo, CN=Trusted CA"
    @caf.not_before = Time.now
    @caf.not_after = @caf.not_before + 365*24*60*60
    @caf.extensions << "keyUsage = critical, keyCertSign"
    @caf.extensions << "basicConstraints = critical,CA:true"
    @caf.extensions << "subjectKeyIdentifier=hash"
    @caf.extensions << "authorityKeyIdentifier=keyid:always"
    @caf.key_type = OpenSSL::PKey::RSA
    @caf.key_size = 1024
    @caf.signing_alg = OpenSSL::Digest::SHA1
    @caf
  end

  def default_ca(goodca, goodca_key)
    @defaultca = goodca
    @defaultca_key = goodca_key
  end


  def cert_factory
    return @cf if @cf
    @cf = CertificateFactory.new
    @cf.ca = @defaultca ? @defaultca : :self
    @cf.ca_key = @defaultca_key ? @defaultca_key : nil
    @cf.subject = "C=US, CN=#{CertMaker::CONFIG["commonname"]}"
    @cf.not_before = Time.now
    @cf.not_after = @cf.not_before + 365*24*60*60
    @cf.extensions << "keyUsage=digitalSignature, keyEncipherment"
    @cf.extensions << "extendedKeyUsage=serverAuth, clientAuth"
    @cf.extensions << "authorityKeyIdentifier=keyid:always"
    @cf.extensions << "subjectKeyIdentifier=hash"
    @cf.extensions << "basicConstraints = critical,CA:FALSE"
    @cf.key_type = OpenSSL::PKey::RSA
    @cf.key_size = 1024
    @cf.signing_alg = OpenSSL::Digest::SHA1
    @cf
  end

  def run2

    goodca, goodca_key = ca_factory.create
    default_ca(goodca, goodca_key)
    puts goodca.to_text

    baseline, baseline_key = cert_factory.create
    puts baseline.to_text

#    cnamemismatch, cnamemismatch_key = cf.create(:subject => "C=US, CN=www.foo.com")
#    puts cnamemismatch.to_text

#    notwebserver, notwebserver_key = cf.create(:extension)
#    selfsigned, selfsigned_key = cf.create(:ca => :self)
#    unknownca, unknownca_key = cf.create(:ca => 

  end
end
