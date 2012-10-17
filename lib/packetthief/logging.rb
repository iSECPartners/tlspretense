module PacketThief
  # Mix-in that provides some private convenience logging functions. Uses the
  # @logger instance variable.
  module Logging
    # An optional Ruby Logger for debugging output. If it is unset, the log
    # methods will be silent.
    attr_accessor :logger

    private

    # Print a message at the specified log severity (prefixed with the component),
    # and display any additional arguments. For example:
    #
    #     dlog(Logger::DEBUG, SomeClass, "hello", :somevalue => 'that value")
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

    def logdebug(msg, args={})
      log(Logger::DEBUG, (([Module, Class].include? self.class) ? self.name : self.class), msg, args)
    end

    def loginfo(msg, args={})
      log(Logger::INFO, self.class, msg, args)
    end

    def logwarn(msg, args={})
      log(Logger::WARN, self.class, msg, args)
    end

    def logerror(msg, args={})
      log(Logger::ERROR, self.class, msg, args)
    end

    def logfatal(msg, args={})
      log(Logger::FATAL, self.class, msg, args)
    end

  end
end
