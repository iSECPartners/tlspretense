module SSLTest
  # Handles a list of arguments, and uses the arguments to run a sequence of tests.
  class Runner
    include PacketThief::Logging

    attr_reader :results

    def initialize(args, stdin, stdout)
      options = RunnerOptions.parse(args)
      @test_list = options.args
      @stdin = stdin
      @stdout = stdout

      @config = Config.new options.options
      @cert_manager = CertificateManager.new(@config.certs)
      @logger = Logger.new(@config.logfile)
      @logger.level = @config.loglevel
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S %Z"
      @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime}:#{severity}: #{msg}\n"
      end
      @app_context = AppContext.new(@config, @cert_manager, @logger)

      @report = SSLTestReport.new
      init_packetthief
    end

    def run
      case @config.action
      when :list
        @stdout.puts "These are the test I will perform and their descriptions:"
        @stdout.puts ''
        @config.tests(@test_list.empty? ? nil : @test_list).each do |test|
          display_test test
        end
      when :runtests
        @stdout.puts "Press spacebar to skip a test, or 'q' to stop testing."
        first = true
        @tests = @config.tests( @test_list.empty? ? nil : @test_list)
        loginfo "Hostname being tested (assuming certs are up to date): #{@config.hosttotest}"
        loginfo "Running #{@tests.length} tests"
        start_packetthief
        @tests.each do |test|
          pause if @config.pause? and not first
          if run_test(test) == :stop
            break
          end
          first = false
        end
        stop_packetthief

        @report.print_results(@stdout)
      else
        raise "Unknown action: #{opts[:action]}"
      end
    end

    # Runs a test based on the test description.
    def run_test(test)
      SSLTestCase.new(@app_context, @report, test).run
    end

    # Initialize custom PacketThief modes of operation. Eg, we use manual when PT
    # does not manage the firewall rules and when it should just return a
    # preconfigured destination, and external for when PT does not manage the
    # firewall rules but still needs to know how to discover the destination.
    def init_packetthief
      PacketThief.logger = @logger
      if @config.packetthief.has_key? 'implementation'
        impl = @config.packetthief['implementation']
        case impl
        when /manual\(/i
          PacketThief.implementation = :manual
          host = /manual\((.*)\)/i.match(impl)[1]
          PacketThief.set_dest(host, @config.packetthief.fetch('dest_port',443))
        when /external\(/i
          real_impl = /external\((.*)\)/i.match(impl)[1]
          PacketThief.implementation = real_impl.strip.downcase.to_sym
        else
          PacketThief.implementation = impl
        end
      end
    end

    def start_packetthief
      ptconf = @config.packetthief
      unless ptconf.has_key? 'implementation' and ptconf['implementation'].match(/external/i)
        PacketThief.redirect(:to_ports => @config.listener_port).where(ptconf).run
      end
      at_exit { PacketThief.revert }
    end

    def stop_packetthief
      PacketThief.revert
    end

    def display_test(test)
      @stdout.printf "%s: %s\n", test['alias'], test['name']
      @stdout.printf "  %s\n", test['certchain'].inspect
      @stdout.puts ''
    end

    def pause
      @stdout.puts "Press Enter to continue."
      @stdin.gets
    end

  end
end
