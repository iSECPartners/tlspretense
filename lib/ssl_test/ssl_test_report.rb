module SSLTest
  class SSLTestReport

    def initialize
      @results = []
    end

    def add_result(result)
      @results << result
    end

    def print_results(out)
        out.puts "Alias            Description      P/F  Expected Actual   Start Time Stop Time "
        out.puts "---------------- ---------------- ---- -------- -------- ---------- ----------"
      @results.each do |r|
        out.printf "%-16.16<id>s %-16.16<description>s %-4.4<passed>s %-8.8<expected_result>s %-8.8<actual_result>s %<start_time>s %<stop_time>s\n", r.to_h
      end

    end

  end
end
