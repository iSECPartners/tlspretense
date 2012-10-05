
require 'fileutils'
require 'yaml'
require 'openssl'

require 'certmaker/ext_core/hash_indifferent_fetch'
require 'certmaker/certificate_factory'
require 'certmaker/certificate_suite_generator'

module CertMaker


  # Generate certificates and keys using +config+.
  #
  # Config is usually a data structure derived from parsing a YAML file.
  def make_certs(config, verbose=false)
    FileUtils.mkdir_p config['certmaker']['outdir'], :verbose => verbose

    certs = CertificateSuiteGenerator.new(config['certs']).certificates

    certs.each do |calias, ck|
      File.open(File.join(config['certmaker']['outdir'],calias+"cert.pem"),"wb") { |f| f.write ck[:cert] }
      File.open(File.join(config['certmaker']['outdir'],calias+"key.pem"),"wb") { |f| f.write ck[:key] }
    end

  end
  module_function :make_certs
end
