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

    def initialize(config, certmanager, testdesc)
      @config = config
      @certmanager = certmanager
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

      PacketThief.redirect(:to_ports => @config.listener_port).where(@config.packetthief).run
      at_exit { PacketThief.revert }
#      if EM.reactor_running?
#        TestListener.start('',@config.listener_port, self)
#      else
        EM.run do
          TestListener.start('',@config.listener_port, self)
          EM.add_periodic_timer(5) { puts "EM connection count: #{EM.connection_count}" }
        end
        puts "Finished test: #{@id}"
#      end
      PacketThief.revert

      SSLTestResult.new(self)
    end

    # callback to get test status.
    def test_completed(listener, result)
      @listener = listener
      @listener.stop_server
      @result = result
      EM.stop_event_loop
    end

  end
end
