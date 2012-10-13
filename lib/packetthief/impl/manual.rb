

module PacketThief
  module Impl
  # PacketThief implementation that does apply any firewall rules. Furthermore,
  # Manual.original_dest will always return a pre-configured destination address.
  class Manual
    module NullRuleHandler

      include Logging

      attr_accessor :active_rules

      # Executes a rule and holds onto it for later removal.
      def run(rule)
      end

      # Reverts all executed rules that this handler knows about.
      def revert
      end
    end
    extend NullRuleHandler

    class NullRule < RedirectRule
      def initialize(handler, rule_number=nil)
        super(handler)
      end
    end

    def self.redirect(args={})
      rule = NullRule.new(self)
      rule.redirect(args)
    end

    def self.set_dest(host, port)
      @dest_host = host
      @dest_port = port
    end

    # Returns the [port, host] for the original destination of +sock+.
    #
    # The Manual implementation only returns a preconfigured original
    # destination. Making it only good for testing clients that only talk to a
    # single remote host.
    def self.original_dest(sock)
      raise "You must call .set_dest(host,port) to set the original_dest in the Manual PacketThief implementation!" if @dest_host == nil or @dest_port == nil
      return [ @dest_port, @dest_host ]

    end

  end

end
end
