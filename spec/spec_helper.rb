$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_group 'Source', '/lib/'
    add_group 'RSpec', '/spec/'
  end
end

require 'rspec'
require 'tlspretense'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
end
RSpec::Expectations.configuration.on_potential_false_positives = :nothing

def with_constants(constants, &block)
  saved_constants = {}
  constants.each do |constant, val|
    saved_constants[ constant ] = Object.const_get( constant )
#    Kernel::silence_warnings { Object.const_set( constant, val ) }
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Object.const_set( constant, val )
    $VERBOSE = old_verbose
  end

  begin
    block.call
  ensure
    constants.each do |constant, val|
#      Kernel::silence_warnings { Object.const_set( constant, saved_constants[ constant ] ) }
      old_verbose = $VERBOSE
      $VERBOSE = nil
      Object.const_set( constant, saved_constants[ constant ] )
      $VERBOSE = old_verbose
    end
  end
end

