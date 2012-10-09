module SSLTest
  class SSLTestResult

    attr_reader   :id
    attr_accessor :description
    attr_accessor :expected_result, :actual_result
    attr_accessor :start_time, :stop_time

    def initialize(testcase_id, passed=true)
      @id = testcase_id
      @passed = true
    end
  end
end
