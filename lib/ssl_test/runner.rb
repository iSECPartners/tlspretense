module SSLTest
  # Handles a list of arguments, and uses the arguments to run a sequence of tests.
  class Runner

    attr_reader :results

    def initialize(args, stdin, stdout)
      @test_list = args
      @stdin = stdin
      @stdout = stdout

      @config = Config.load_conf
      @cert_manager = CertificateManager.new(@config.certs)
      @results = []
    end

    def run

      @results = []
      @config.tests( @test_list.empty? ? nil : @test_list).each do |test|
        run_test test
      end
    end

    # Runs a test based on the test description.
    def run_test(test)
      @results << SSLTestCase.new(test, @cert_manager).run
    end

  end
end
