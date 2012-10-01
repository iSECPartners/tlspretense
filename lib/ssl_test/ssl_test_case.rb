module SSLTest
  class SSLTestCase

    attr_reader :id
    attr_reader :title
    attr_reader :certchain
    attr_reader :expected_result

    def initialize(testconf, certmanager)
      @raw = testconf.dup
      @id = @raw['alias']
      @title = @raw['name']
      @certchain = @raw['certchain']
      @expected_result = @raw['expected_result']
      @certmanager = certmanager
    end

    def run
#      EM.run do
#        SSLInterceptor
#      end
      #return result... success fail, reason for fail?
    end
  end
end
