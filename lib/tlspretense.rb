
require 'fileutils'

require 'ssl_test'
require 'certmaker'
require 'certmaker/runner'

module TLSPretense
  autoload :App,  'tlspretense/app'
  autoload :InitRunner, 'tlspretense/init_runner'
end
