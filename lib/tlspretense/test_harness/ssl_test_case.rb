module TLSPretense
module TestHarness
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
      @raw = testdesc.dup
      @id = @raw['alias']
      @description = @raw['name']
      @certchainalias = @raw['certchain']
      @expected_result = @raw['expected_result']
    end

    def certchain
      @certchain ||= @appctx.cert_manager.get_chain(@certchainalias)
    end

    def keychain
      @keychain ||= @appctx.cert_manager.get_keychain(@certchainalias)
    end

    def hosttotest
      @hosttotest ||= @appctx.config.hosttotest
    end

  end
end
end
