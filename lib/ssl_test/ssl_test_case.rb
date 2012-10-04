module SSLTest
  class SSLTestCase

    attr_reader :id
    attr_reader :title
    attr_reader :certchainalias
    attr_reader :expected_result

    attr_reader :certchain
    attr_reader :key
    attr_reader :hosttotest

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
      @certchain = @certmanager.get_chain(@certchainalias)
      @key = @certmanager.get_key(@certchainalias[0])
      @hosttotest = @config.hosttotest

      PacketThief.redirect(:to_ports => @config.listener_port).where(:protocol => :tcp, :dest_port => @config.dest_port).run
      at_exit { PacketThief.revert }
      EM.run do
        TestListener.start('127.0.0.1',@config.listener_port, self)
      end
      PacketThief.revert

      SSLTestResult.new(self)
    end

  end
end
