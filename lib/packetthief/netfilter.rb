
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
          args << '--destination-port' << rule.rulespec[:destination_port].to_s if rule.rulespec.has_key? :destination_port
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


    class IPTablesRule
      attr_accessor :handler
      attr_accessor :table
      attr_accessor :chain
      attr_accessor :rulespec
      attr_accessor :redirectspec

      def initialize(handler, table, chain, args={})
        @handler = handler
        @table = table
        @chain = chain
      end

      # specify an original destination
      def where(args)
        rule = clone
        rule.rulespec = args
        rule
      end

      def redirect(args)
        rule = clone
        rule.redirectspec = args
        rule
      end

      def run
        @handler.run(self)
      end
    end


    def self.divert(args={})
      IPTablesRule.new(self,'nat','PREROUTING', args)
    end

  end
end
