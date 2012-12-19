module SSLTest
  # Represents a single test case.
  class SSLTestCase
    include PacketThief::Logging

    attr_reader :id
    attr_reader :description
    attr_reader :certchainalias
    attr_reader :expected_result

    attr_reader :certchain
    attr_reader :keychain
    attr_reader :hosttotest
    attr_reader :goodcacert
    attr_reader :goodcakey

    def self.factory(appctx, test_data, tests_to_create)
      if tests_to_create == [] or tests_to_create == nil
        final_test_data = test_data
      else
        final_test_data = tests_to_create.map { |name| test_data.select { |test| test['alias'] == name }[0] }
      end
      final_test_data.map { |data| SSLTestCase.new(appctx, data) }
    end

    def initialize(appctx, testdesc)
      @appctx = appctx
      @config = @appctx.config
      @certmanager = @appctx.cert_manager
      @raw = testdesc.dup
      @id = @raw['alias']
      @description = @raw['name']
      @certchainalias = @raw['certchain']
      @expected_result = @raw['expected_result']

      @certchain = @certmanager.get_chain(@certchainalias)
      @keychain = @certmanager.get_keychain(@certchainalias)
      @hosttotest = @config.hosttotest

      @goodcacert = @certmanager.get_cert("goodca")
      @goodcakey = @certmanager.get_key("goodca")
    end

    # Sets up and launches the current test. It gathers the certificates and
    # keys needed to launch a TestListener, and
    # (currently) also sets up the keyboard user interface.
    def run
      @certchain = @certmanager.get_chain(@certchainalias)
      @keychain = @certmanager.get_keychain(@certchainalias)
      @hosttotest = @config.hosttotest

      @goodcacert = @certmanager.get_cert("goodca")
      @goodcakey = @certmanager.get_key("goodca")

      @status
    end

  end
end
