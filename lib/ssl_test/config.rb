module SSLTest
  # Loads and interprets the configuration file.
  class Config

    DEFAULT = "config.yml"

    attr_reader :raw
    attr_reader :certs

    def self.load_conf(opts)
      Config.new(opts)
    end

    # TODO: do some basic type validation on the config file.
    def initialize(opts)
      @opts = opts

      @raw = YAML.load_file(@opts[:config])
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

    def testing_method
      @raw['testing_method']
    end

    def packetthief
      pt = @raw['packetthief'].dup
      newvals = {}
      pt.each_pair do |k,v|
        if k.kind_of? String
          newvals[k.to_sym] = v
        end
      end
      pt.merge! newvals
      pt
    end

    def pause?
      @opts[:pause]
    end

    def action
      @opts[:action]
    end

    def loglevel
      levelstr = if @opts.has_key? :loglevel
        @opts[:loglevel].upcase
      elsif @raw.has_key? 'log' and @raw['log'].has_key? 'level'
        @raw['log']['level'].upcase
      else
        'INFO'
      end
      Logger.const_get(levelstr)
    end

    def logfile
      if @opts[:logfile] == '-'
        STDOUT
      else
        @opts[:logfile]
      end
    end


  end
end
