module TLSPretense
module TestHarness

  class RunnerOptions

    DEFAULT_OPTS = {
      :pause => false,
      :config => Config::DEFAULT,
      :action => :runtests,
      :loglevel => 'INFO',
      :logfile => '-'
    }

    # Parsed command line options.
    attr_reader :options

    # Any command line arguments that are not options.
    attr_reader :args

    def self.parse(args)
      opts = new(args)
      opts.parse
      opts
    end

    def initialize(args)
      @orig_args = args
    end

    def parse
      @options = DEFAULT_OPTS.dup

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] [tests to run]"

        opts.on("-p","--[no-]pause", "Pause between tests") do
          @options[:pause] = true
        end

        opts.on("-c", "--config path/to/config.yml",
                "Specify a custom config.yml file",
                "  (Default: #{DEFAULT_OPTS[:config]})") do |confname|
          @options[:config] = confname
        end

        opts.on("-l","--list", "List all tests (or those specified on the command line") do
          @options[:action] = :list
        end

        opts.on("--log-level=loglevel", "Set the log level. It can be one of:",
                "  DEBUG, INFO, WARN, ERROR, FATAL", "  (Default: INFO, or whatever config.yml sets)") do |level|
          @options[:loglevel] = level
        end

        opts.on("--log-file=somefile.log", "Specify the file to write logs to.","  (Default: - (STDOUT))") do |file|
          @options[:logfile] = file
        end
        opts.on_tail('-h', '--help', "Print this help message.") do
          puts opts
          exit
        end

      end

      @args = @orig_args.dup
      opts.parse!(@args)
    end

  end
end
end
