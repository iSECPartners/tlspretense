module SSLTest
  class SSLTestCase

    attr_reader :id
    attr_reader :title
    attr_reader :certchainalias
    attr_reader :expected_result

    attr_reader :certchain
    attr_reader :keychain
    attr_reader :hosttotest

    attr_reader :goodcacert
    attr_reader :goodcakey

    def initialize(config, certmanager, report, testdesc)
      @config = config
      @certmanager = certmanager
      @report = report
      @raw = testdesc.dup
      @id = @raw['alias']
      @title = @raw['name']
      @certchainalias = @raw['certchain']
      @expected_result = @raw['expected_result']
    end

    def run
      puts "Starting test: #{@id}"
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
          TestListener.start('',@config.listener_port, self)
          EM.add_periodic_timer(5) { puts "EM connection count: #{EM.connection_count}" }
        end
      end

#      SSLTestResult.new(self)
    end

    # callback to get test status.
    def test_completed(listener, actual_result)
      str = SSLTestResult.new(@id, (actual_result.to_s == @expected_result))
      str.description = @title
      str.expected_result = @expected_result
      str.actual_result = actual_result.to_s
      str.start_time = @start_time
      str.stop_time = Time.now

      @report.add_result(str)

      puts "Finished test: #{@id}"
      listener.stop_server

      EM.stop_event_loop if @started_em
      PacketThief.revert
    end

  end
end
