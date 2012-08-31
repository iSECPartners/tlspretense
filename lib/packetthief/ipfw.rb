

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
      # Executes a rule and holds onto it for later removal.
      def run(rule)
        @active_rules ||= []

        args = ['/sbin/ipfw', 'add', '1013'] # TODO: make the rule number customizable

        if rule.redirectspec
          if rule.redirectspec.has_key? :to_ports
            args << 'fwd'
            args << "127.0.0.1,#{rule.redirectspec[:to_ports].to_s}"
          else
            raise "Rule lacks a valid redirect: #{rule.inspect}"
          end
        end

        if rule.rulespec
          args << rule.rulespec.fetch(:protocol,'ip').to_s

          args << 'from'
          args << rule.rulespec.fetch(:source_address, 'any').to_s
          args << rule.rulespec[:source_port].to_s if rule.rulespec.has_key? :source_port

          args << 'to'
          args << rule.rulespec.fetch(:dest_address, 'any').to_s
          args << rule.rulespec[:dest_port].to_s if rule.rulespec.has_key? :dest_port
        end


        unless system(*args)
          raise "Command #{args.inspect} exited with error code #{$?.inspect}"
        end

        @active_rules << 1013
      end

      # Reverts all executed rules that this handler knows about.
      def revert
        return if @active_rules == nil or @active_rules.empty?

        @active_rules.each do |rule|

        end
      end
    end
    extend IpfwRuleHandler

    def self.redirect(args={})
      rule = RedirectRule.new(self)
      rule.redirect(args)
    end

  end
end
