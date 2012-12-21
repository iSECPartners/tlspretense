require 'fileutils'

require 'packetthief'
require 'certmaker'
require 'certmaker/runner'

module TLSPretense
  class CleanExitError < StandardError ; end

  autoload :App,        'tlspretense/app'
  autoload :InitRunner, 'tlspretense/init_runner'
  autoload :TestHarness, 'tlspretense/test_harness'
  autoload :VERSION,    'tlspretense/version'
end
