module SSLTest
  # Represents a single test case. It performs the test it represents and adds
  # its result to a report.
  class SSLTestCase

    attr_reader :id
    attr_reader :description

    def initialize(appctx, report, testdesc)
      @appctx = appctx
      @config = @appctx.config
      @certmanager = @appctx.cert_manager
      @report = report
      @raw = testdesc.dup
      @id = @raw['alias']
      @description = @raw['name']
      @certchainalias = @raw['certchain']
      @expected_result = @raw['expected_result']
    end

    # Sets up and launches the current test. It gathers the certificates and
    # keys needed to launch a TestListener, sets up PacketThief, and
    # (currently) also sets up the keyboard user interface.
    def run
      @appctx.logger.info "#{@id}: Starting test"
      @certchain = @certmanager.get_chain(@certchainalias)
      @keychain = @certmanager.get_keychain(@certchainalias)
      @hosttotest = @config.hosttotest

      @goodcacert = @certmanager.get_cert("goodca")
      @goodcakey = @certmanager.get_key("goodca")

      @start_time = Time.now

      PacketThief.redirect(:to_ports => @config.listener_port).where(@config.packetthief).run
      at_exit { PacketThief.revert }

      @started_em = false
      if EM.reactor_running?
        TestListener.start('',@config.listener_port, self)
      else
        @started_em = true
        EM.run do
          # @listener handles the initial server socket, not the accepted connections.
          # h in the code block is for each accepted connection.
          @listener = TestListener.start('',@config.listener_port, @goodcacert, @goodcakey, @hosttotest, @certchain, @keychain[0]) do |h|
            h.on_test_completed { |result| self.test_completed result }
          end
          @listener.logger = @appctx.logger
          EM.open_keyboard InputHandler do |h|
            h.on(' ') { self.test_completed :skipped }
            h.on('q') { self.stop_testing }
          end
          EM.add_periodic_timer(5) { @appctx.logger.info "EM connection count: #{EM.connection_count}" }
        end
      end
    end

    def cleanup
      @listener.stop_server if @listener
      EM.stop_event_loop if @started_em
      PacketThief.revert
    end

    # Called when a test completes or is skipped. It adds an SSLTestResult to
    # the report, and it cleans up after itself.
    def test_completed(actual_result)
      return if actual_result == :running

      str = SSLTestResult.new(@id, (actual_result.to_s == @expected_result))
      str.description = @description
      str.expected_result = @expected_result
      str.actual_result = actual_result.to_s
      str.start_time = @start_time
      str.stop_time = Time.now

      @report.add_result(str)

      if actual_result == :skipped
        @appctx.logger.info "#{@id}: Skipping test"
      else
        @appctx.logger.info "#{@id}: Finished test"
      end

      cleanup
    end

    # Callback to cleanup and exit.
    def stop_testing
      cleanup
      exit
    end

  end
end
