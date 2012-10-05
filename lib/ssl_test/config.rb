module SSLTest
  class Config

    DEFAULT = "config.yml"

    attr_reader :raw
    attr_reader :certs

    def self.load_conf(filename=nil)
      filename = DEFAULT if filename == nil

      Config.new(filename)
    end

    # TODO: do some basic type validation on the config file.
    def initialize(filename)
      @raw = YAML.load_file(filename)
      @certs = @raw['certs']
    end

    def tests(test_list=nil)
      return @raw['tests'] unless test_list != nil
      test_list.map { |name| @raw['tests'].select { |test| test['alias'] == name }[0] }
    end

    def hosttotest
      @raw['hostname']
    end

    def listener_port
      @raw['listener_port']
    end

    def packetthief
      @raw['packetthief']
    end

  end
end
