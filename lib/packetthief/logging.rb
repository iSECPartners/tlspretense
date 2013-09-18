module PacketThief
  # Mix-in that provides some private convenience logging functions. Uses the
  # logger specified by this module. To set the current logger for all of
  # PacketThief:
  #
  #     PacketThief::Logging.logger = Logger.new
  module Logging

    class << self

      # An optional Ruby Logger for debugging output. If it is unset, the log
      # methods will be silent.
      attr_accessor :logger

      # Print a message at the specified log severity (prefixed with the component),
      # and display any additional arguments. For example:
      #
      #     log(Logger::DEBUG, SomeClass, "hello", :somevalue => 'that value")
      #
      # Will print the message: "SomeClass: hello: somevalue=that value" at the
      # debug log level.
      def log(level, component, msg, args={})
        if @logger
          unless args.empty?
            kvstr = args.map { |pair| pair[0].to_s + ': ' + pair[1].inspect }.sort.join(', ')
            msg += ": " + kvstr
          end
          @logger.log(level, component.to_s + ': ' + msg)
        end
      end

    end

    private

    def logdebug(msg, args={})
      Logging.log(Logger::DEBUG, (([Module, Class].include? self.class) ? self.name : self.class), msg, args)
    end

    def loginfo(msg, args={})
      Logging.log(Logger::INFO, self.class, msg, args)
    end

    def logwarn(msg, args={})
      Logging.log(Logger::WARN, self.class, msg, args)
    end

    def logerror(msg, args={})
      Logging.log(Logger::ERROR, self.class, msg, args)
    end

    def logfatal(msg, args={})
      Logging.log(Logger::FATAL, self.class, msg, args)
    end

  end
end
