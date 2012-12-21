require 'fileutils'

require 'packetthief'
require 'tlspretense/cert_maker/runner'

module TLSPretense
  class CleanExitError < StandardError ; end

  autoload :App,        'tlspretense/app'
  autoload :InitRunner, 'tlspretense/init_runner'
  autoload :TestHarness, 'tlspretense/test_harness'
  autoload :VERSION,    'tlspretense/version'
  autoload :CertMaker,  'tlspretense/cert_maker'
end
