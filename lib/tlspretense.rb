require 'fileutils'

require 'ssl_test'
require 'certmaker'
require 'certmaker/runner'

module TLSPretense
  class CleanExitError < StandardError ; end

  autoload :App,        'tlspretense/app'
  autoload :InitRunner, 'tlspretense/init_runner'
  autoload :VERSION,    'tlspretense/version'
end
