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
  run         Run all or some of the test cases. Call `run -h` for more
              information.
  list, ls    List all or some of the test cases (equivalent to `run -l`).
  ca          Checks for a ca, and generates it if needed.
  certs       (Re)generate a suite of test certificates.
  cleancerts  Remove the certs directory.
QUOTE
    end

    def run
      case @action
      when 'run'
        SSLTest::Runner.new(@action_args, @stdin, @stdout).run
      when 'list', 'ls'
        SSLTest::Runner.new(['--list'] + @action_args, @stdin, @stdout).run
      when 'ca'
        CertMaker::Runner.new.ca
      when 'certs'
        CertMaker::Runner.new.certs
      when 'cleancerts'
        CertMaker::Runner.new.clean
      else
        usage
      end
    end
  end
end
