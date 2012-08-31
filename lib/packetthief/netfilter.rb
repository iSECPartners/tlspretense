
module PacketThief
  # PacketThief implemented using the Linux kernel's Netfilter.
  #
  # This is roughly equivalent to:
  #
  # echo 1 > /proc/sys/net/ipv4/ip_forward
  # iptables -t nat -A PREROUTING -p tcp --destination-port <DEST> -j REDIRECT --to-ports <LISTENER>
  #
  # Currently only implements IPv4.
  class Netfilter

    # Manages IPTablesRules. It actually runs the rule, and it tracks the rule
    # so it can be deleted later.
    module IPTablesRuleHandler
      # Executes a rule and holds onto it for later removal.
      def run(rule)
        @active_rules ||= []

        args = ['/sbin/iptables', '-t', rule.table, '-A', rule.chain]

        if rule.rulespec
          args << '-p' << rule.rulespec[:protocol].to_s if rule.rulespec.has_key? :protocol
          args << '--destination-port' << rule.rulespec[:dest_port].to_s if rule.rulespec.has_key? :dest_port
        end

        if rule.redirectspec
          args << '-j' << 'REDIRECT'
          args << '--to-ports' << rule.redirectspec[:to_ports].to_s if rule.redirectspec.has_key? :to_ports
        end

        unless system(*args)
          raise "Command #{args.inspect} exited with error code #{$?.inspect}"
        end

        @active_rules << rule
      end

      # Reverts all executed rules that this handler knows about.
      def revert
        return if @active_rules == nil or @active_rules.empty?

        @active_rules.each do |rule|

        end
      end
    end
    extend IPTablesRuleHandler

    # Adds IPTables specific details to a Redirectrule.
    class IPTablesRule < RedirectRule

      attr_accessor :table
      attr_accessor :chain

      def initialize(handler, table, chain)
        super(handler)
        @table = table
        @chain = chain
      end
    end

    def self.redirect(args={})
      rule = IPTablesRule.new(self,'nat','PREROUTING')
      rule.redirect(args)
    end

  end
end
