require 'optparse'
require 'logger'

require 'eventmachine'
require 'termios'

require 'packetthief'
require 'tlspretense/ext_core/io_raw_input'

module TLSPretense
  module TestHarness
    autoload :AppContext,         'tlspretense/test_harness/app_context'
    autoload :CertificateManager, 'tlspretense/test_harness/certificate_manager'
    autoload :Config,             'tlspretense/test_harness/config'
    autoload :InputHandler,       'tlspretense/test_harness/input_handler'
    autoload :RunnerOptions,      'tlspretense/test_harness/runner_options'
    autoload :Runner,             'tlspretense/test_harness/runner'
    autoload :SSLTestCase,        'tlspretense/test_harness/ssl_test_case'
    autoload :SSLTestReport,      'tlspretense/test_harness/ssl_test_report'
    autoload :SSLTestResult,      'tlspretense/test_harness/ssl_test_result'
    autoload :TestListener,       'tlspretense/test_harness/test_listener'
    autoload :TestManager,        'tlspretense/test_harness/test_manager'
  end
end
