

module PacketThief
module Impl
  # Use Ipfw to redirect traffic.
  #
  # Needed in at least Mac OS X 10.6 and later[1]?:
  #     sysctl -w net.inet.ip.scopedroute=0
  #
  # [1]: https://trac.macports.org/wiki/howto/SetupInterceptionSquid
  #
  # sudo ipfw add 1013 fwd 127.0.0.1,3129 tcp from any to any 80 recv INTERFACE
  class Ipfw
    module IpfwRuleHandler
      attr_accessor :active_rules

      # Executes a rule and holds onto it for later removal.
      def run(rule)
        @active_rules ||= []

        args = ['/sbin/ipfw', 'add', 'set', '30'] # TODO: make the rule number customizable

        args.concat rule.to_ipfw_command

        if /darwin/ === RUBY_PLATFORM
          unless system(*%W{/usr/sbin/sysctl -w net.inet.ip.scopedroute=0})
            raise "Command #{args.inspect} exited with error code #{$?.inspect}"
          end
        end

        # run the command
        unless system(*args)
          raise "Command #{args.inspect} exited with error code #{$?.inspect}"
        end

        @active_rules << rule
      end

      # Reverts all executed rules that this handler knows about.
      def revert
        return if @active_rules == nil or @active_rules.empty?

#        @active_rules.each do |rule|
          args = ['/sbin/ipfw', 'del', 'set', '30']
#          args.concat rule.to_ipfw_command
          unless system(*args)
            raise "Command #{args.inspect} exited with error code #{$?.inspect}"
          end
#        end

        @active_rules = []
      end
    end
    extend IpfwRuleHandler

    class IpfwRule < RedirectRule

      attr_accessor :rule_number

      def initialize(handler, rule_number=nil)
        super(handler)
        @rule_number = rule_number
      end

      def to_ipfw_command
        args = []

        if self.redirectspec
          if self.redirectspec.has_key? :to_ports
            args << 'fwd'
            args << "127.0.0.1,#{self.redirectspec[:to_ports].to_s}"
          else
            raise "Rule lacks a valid redirect: #{self.inspect}"
          end
        end

        if self.rulespec
          args << self.rulespec.fetch(:protocol,'ip').to_s

          args << 'from'
          args << self.rulespec.fetch(:source_address, 'any').to_s
          args << self.rulespec[:source_port].to_s if self.rulespec.has_key? :source_port

          args << 'to'
          args << self.rulespec.fetch(:dest_address, 'any').to_s
          args << 'dst-port' << self.rulespec[:dest_port].to_s if self.rulespec.has_key? :dest_port

          args << 'recv' << self.rulespec[:in_interface].to_s if self.rulespec.has_key? :in_interface
        end

        args
      end
    end

    def self.redirect(args={})
      rule = IpfwRule.new(self)
      rule.redirect(args)
    end

    # Returns the [port, host] for the original destination of +sock+.
    #
    # +Sock+ can be a Ruby socket or an EventMachine::Connection (including
    # handler modules, which are mixed in to an anonymous descendent of
    # EM::Connection).
    #
    # When Ipfw uses a fwd/forward rule to redirect a connection to a local
    # socket, the destination address remains unchanged, meaning that C's
    # getsockname() will return the original destination.
    def self.original_dest(sock)
      if sock.respond_to? :getsockname
        sockname = sock.getsockname
      elsif sock.respond_to? :get_sockname
        sockname = sock.get_sockname
      else
        raise ArgumentError, "#{sock.inspect} supports neither :getsockname nor :get_sockname!"
      end
      Socket::unpack_sockaddr_in(sockname)
    end
  end

end
end
