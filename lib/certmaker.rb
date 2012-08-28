
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

  # Create a CA.
  # The CA is stored in files: #{handle}cert.pem and #{handle}key.pem, and both
  # the certificate object and key are returned.
  def create_ca(handle, args={})
    cert, key = ca_factory.create(args)
    File.open("#{handle}cert.pem","wb") { |f| f.print cert.to_pem }
    File.open("#{handle}key.pem","wb") { |f| f.print key.to_pem }
    return cert, key
  end


  # Create a certificate.

  def create_cert(handle, args={})
    cert, key = cert_factory.create(args)
    File.open("#{handle}cert.pem","wb") { |f| f.print cert.to_pem }
    File.open("#{handle}key.pem","wb") { |f| f.print key.to_pem }
    return cert, key

  end

  def run2
    include FileUtils
    cd "ssl"

    goodca, goodca_key = create_ca "ca"
    default_ca(goodca, goodca_key)
#    puts goodca.to_text

    create_cert("00-baseline")

    create_cert("01-cnamemismatch", :subject => "C=US, CN=www.foo.com")

    create_cert("02-notwebserver", :blockextension => ["extendedKeyUsage"])

    # The authorityKeyIdentifier does not exist before self-signing a cert.
    create_cert("03-selfsigned", :ca => :self, :blockextension => ["authorityKeyIdentifier"])

    badca, badca_key = create_ca("04ca", :subject => "C=US, CN=Evil CA")
    create_cert("04-unknownca", :ca => badca, :ca_key => badca_key)

    badinterm, badinterm_key = create_cert("05intermediate", :subject => "C=US, CN=www.bar.com")
    create_cert("05-signedbyintermediate", :ca => badinterm, :ca_key => badinterm_key)

    cert, key = create_cert("06-expired", :not_before => Time.now - 60*60*24, :not_after => Time.now - 60*60)

    create_cert("07-md4", :signing_alg => OpenSSL::Digest::MD4)

    create_cert("08-md5", :signing_alg => OpenSSL::Digest::MD5)

  end
end
