
require 'fileutils'
require 'yaml'

require 'certmaker/run'
require 'certmaker/certificate'

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
end
