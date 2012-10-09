

module SSLTest
  # EM handler to handle keyboard input while a test is running.
  module InputHandler
    def initialize(testcase, listenerserver, stdin)
      @testcase = testcase
      @listenerserver = listenerserver
      @stdin = stdin

      # Set the term to accept keystrokes immediately.
      @oldtermios = Termios.tcgetattr(@stdin)
      newt = @oldtermios.dup
      newt.c_lflag &= ~Termios::ICANON
      newt.c_lflag &= ~Termios::ECHO
      Termios.tcsetattr(@stdin, Termios::TCSANOW, newt)
    end

    # mirror the TestListener
    def stop_server
      @listenerserver.close
    end

    def unbind
      # Clean up by resotring the old termios
      Termios.tcsetattr(@stdin, Termios::TCSANOW, @oldtermios)
    end

    # Receives one character at a time.
    def receive_data(data)
      case data
      when ' '
        do_skip_test
      when 'q'
        do_stop_testing
      end
    end

    def do_skip_test
      @testcase.test_completed(self, :skipped)
    end

    def do_stop_testing
      @testcase.stop_testing
    end

  end
end
