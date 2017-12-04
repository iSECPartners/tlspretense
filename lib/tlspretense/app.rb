module TLSPretense
  class App
    def initialize(args, stdin, stdout)
      @args = args
      @stdin = stdin
      @stdout = stdout
      @action_args = args.dup
      @action = @action_args.shift
    end

    def usage
      @stdout.puts <<-QUOTE
Usage: #{0} action arguments...

Actions:
  init PATH   Creates a new TLSPretense working directory. This includes
              configuration files and test certificates.
  run         Run all or some of the test cases. Call `run -h` for more
              information.
  list, ls    List all or some of the test cases (equivalent to `run -l`).
  ca          Checks for a ca, and generates it if needed.
  certs       (Re)generate a suite of test certificates.
  cleancerts  Remove the certs directory.
QUOTE
    end

    def run
      begin
        case @action
        when 'init'
          InitRunner.new(@action_args, @stdin, @stdout).run
        when 'run'
          unless TestHarness::Runner.new(@action_args, @stdin, @stdout).run
            return 1
          end
        when 'list', 'ls'
          TestHarness::Runner.new(['--list'] + @action_args, @stdin, @stdout).run
        when 'ca'
          CertMaker::Runner.new.ca
        when 'certs'
          CertMaker::Runner.new.certs
        when 'cleancerts'
          CertMaker::Runner.new.clean
        else
          usage
        end
      rescue CleanExitError => e
        @stdout.puts ""
        @stdout.puts "#{e.class}: #{e}"
        return 1
      end
      0
    end
  end
end
