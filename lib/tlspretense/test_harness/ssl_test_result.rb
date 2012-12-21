module TLSPretense
module TestHarness
  # SSLTestResults are created by running SSLTestCases. They are then added to
  # an SSLTestReport so that they can be included in that report.
  class SSLTestResult

    attr_reader   :id
    attr_accessor :description
    attr_accessor :expected_result, :actual_result
    attr_accessor :start_time, :stop_time

    def passed? ; @passed ; end

    def initialize(testcase_id, passed=false)
      @id = testcase_id
      @passed = passed
    end

    def to_h
      {
        :id => id,
        :passed => passed? ? "Pass" : "Fail",
        :description => description,
        :expected_result => expected_result,
        :actual_result => actual_result,
        :start_time => start_time,
        :stop_time => stop_time,
      }
    end
  end
end
end
