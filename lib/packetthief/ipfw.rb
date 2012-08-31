

module PacketThief
  # Use Ipfw to redirect traffic.
  #
  # Needed in at least Mac OS X 10.6 and later[1]?:
  #     sysctl -w net.inet.ip.scopedroute 0
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

        args = ['/sbin/ipfw', 'add'] # TODO: make the rule number customizable

        args.concat rule.to_ipfw_command

        # run the command
        unless system(*args)
          raise "Command #{args.inspect} exited with error code #{$?.inspect}"
        end

        @active_rules << rule
      end

      # Reverts all executed rules that this handler knows about.
      def revert
        return if @active_rules == nil or @active_rules.empty?

        @active_rules.each do |rule|
          args = ['/sbin/ipfw', 'del',]
          args.concat rule.to_ipfw_command
          unless system(*args)
            raise "Command #{args.inspect} exited with error code #{$?.inspect}"
          end
        end

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
          args << self.rulespec[:dest_port].to_s if self.rulespec.has_key? :dest_port
        end
      end
    end

    def self.redirect(args={})
      rule = IpfwRule.new(self)
      rule.redirect(args)
    end

  end
end
