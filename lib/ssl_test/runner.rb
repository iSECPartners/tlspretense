module SSLTest
  # Handles a list of arguments, and uses the arguments to run a sequence of tests.
  class Runner

    attr_reader :results

    DEFAULT_OPTS = {
        :pause => false,
        :config => Config::DEFAULT,
        :action => :runtests,
        :loglevel => 'INFO',
        :logfile => '-'
      }

    def parse_args(args)
      options = DEFAULT_OPTS.dup

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] [tests to run]"

        opts.on("-p","--[no-]pause", "Pause between tests") do |v|
          options[:pause] = true
        end

        opts.on("-c", "--config path/to/config.yml",
                "Specify a custom config.yml file",
                "  (Default: #{DEFAULT_OPTS[:config]})") do |confname|
          options[:config] = confname
        end

        opts.on("-l","--list", "List all tests (or those specified on the command line") do |v|
          options[:action] = :list
        end

        opts.on("--log-level=loglevel", "Set the log level. It can be one of:",
                "  DEBUG, INFO, WARN, ERROR, FATAL", "  (Default: INFO, or whatever config.yml sets)") do |l|
          options[:loglevel] = l
        end

        opts.on("--log-file=somefile.log", "Specify the file to write logs to.","  (Default: - (STDOUT))") do |l|
          options[:logfile] = l
        end

      end

      args = args.dup
      opts.parse!(args)
      return [options, args]
    end

    def initialize(args, stdin, stdout)
      @options, args = parse_args(args)
      @test_list = args
      @stdin = stdin
      @stdout = stdout

      @config = Config.new @options
      @cert_manager = CertificateManager.new(@config.certs)
      @logger = Logger.new(@config.logfile)
      @logger.level = @config.loglevel
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S %Z"
      @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime}:#{severity}: #{msg}\n"
      end
      @app_context = AppContext.new(@config, @cert_manager, @logger)
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

      @report = SSLTestReport.new
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
        @report = SSLTestReport.new
        first = true
        @config.tests( @test_list.empty? ? nil : @test_list).each do |test|
          pause if @config.pause? and not first
          run_test test
          first = false
        end
        @report.print_results(@stdout)
      else
        raise "Unknown action: #{opts[:action]}"
      end
    end

    # Runs a test based on the test description.
    def run_test(test)
      SSLTestCase.new(@app_context, @report, test).run
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
