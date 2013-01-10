require 'fileutils'
require 'openssl'
require 'yaml'

require 'tlspretense/ext_core/hash_indifferent_fetch'

module TLSPretense
  module CertMaker

    autoload :CertificateFactory,         'tlspretense/cert_maker/certificate_factory'
    autoload :CertificateSuiteGenerator,  'tlspretense/cert_maker/certificate_suite_generator'
    autoload :SubjectAltNameFactory,      'tlspretense/cert_maker/subject_alt_name_factory'


  # Generate certificates and keys using +config+.
  #
  # Config is usually a data structure derived from parsing a YAML file.
  def make_certs(config, verbose=false)
    FileUtils.mkdir_p config['certmaker']['outdir'], :verbose => verbose

    certs = CertificateSuiteGenerator.new(config['certs'], config['hostname'], config['certmaker']).certificates

    certs.each do |calias, ck|
      File.open(File.join(config['certmaker']['outdir'],calias+"cert.pem"),"wb") { |f| f.write ck[:cert] }
      File.open(File.join(config['certmaker']['outdir'],calias+"key.pem"),"wb") { |f| f.write ck[:key] }
    end

  end
  module_function :make_certs

  # Ensure that the custom ca exists.
  def make_ca(config, verbose=false)
    unless config['certmaker'].has_key? 'customgoodca'
      puts "CertMaker does not have a 'customgoodca' entry, so a CA will be regenerated every time."
      return
    end

    cacert = config['certmaker']['customgoodca']['certfile']
    cakey = config['certmaker']['customgoodca']['keyfile']

    if File.exist? cacert and File.exist? cakey
      puts "CA and CA's key already exist."
    elsif File.exist? cacert and not File.exist? cakey
      raise "CA certificate exists, but the key file does not exist?!"
    elsif not File.exist? cacert and File.exist? cakey
      raise "CA certificate does not exist, but the key file exists?!"
    else
      puts "Generating a new CA"
      cacertdir = File.dirname(config['certmaker']['customgoodca']['certfile'])
      FileUtils.mkdir_p cacertdir, :verbose => verbose
      cakeydir = File.dirname(config['certmaker']['customgoodca']['keyfile'])
      FileUtils.mkdir_p cakeydir, :verbose => verbose
      csg = CertificateSuiteGenerator.new(config['certs'], config['hostname'], config['certmaker'])
      csg.generate_certificate('goodca',config['certs']['goodca'])
      cadata = csg.certificates['goodca']
      File.open(cacert,"wb") { |f| f.write cadata[:cert] }
      File.open(cakey,"wb") { |f| f.write cadata[:key] }
      puts "New CA generated."
      puts "Make sure you remove or comment out the passphrase in config.yml if you had one previously set!"
    end
  end
  module_function :make_ca

  end
end
