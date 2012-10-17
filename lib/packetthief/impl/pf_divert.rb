

module PacketThief
module Impl
  # Untested and likely broken PacketThief implementation that uses PF's
  # divert-to to redirect traffic. It is currently untested, and it requires a
  # newer version of PF to redirect traffic than is available in Mac OS X 10.7
  # (and probably 10.8)
  #
  # == Capturing Traffic
  #
  # It works by dynamically changing the rules in the "packetthief" anchor. To
  # use it, you must add the following to your /etc/pf.conf file in the
  # "Packet Filtering" section::
  #
  #     anchor "packetthief"
  #
  # Then you must reload your pf config by rebooting or by executing:
  #
  #     sudo pfctl -f /etc/pf.conf
  #
  # When PacketThief adds a rule, it constructs a new rule set for the
  # packetthief anchor and replaces the current ruleset in the anchor by
  # calling:
  #
  #     echo "#{our rules}" | pfctl -a packetthief -f -
  #
  # Rules look something like:
  #
  #     pass in on en1 proto tcp from any to any port 443 divert-to 127.0.0.1 port 54321
  #
  # == Acquiring the original destination
  #
  # According to [1], if we use a divert-to rule, we can get the original
  # destination using getsockname(2) instead of having to perform ioctl
  # operations on the /dev/pf pseudo-device.
  #
  # [1]: http://www.openbsd.org/cgi-bin/man.cgi?query=pf.conf&sektion=5&arch=&apropos=0&manpath=OpenBSD+Current
  #
  #
  # == Alternative implementations
  #
  # TODO:
  #
  # divert-to is too new of Mac OS X 10.7 (Lion is using a relatively "old"
  # implementation of PF).
  #
  # A possible alternative is to use rdr rules:
  #
  #     rdr on en1 proto tcp from any to any port 443 -> 127.0.0.1 port 54321
  #
  # This also requires:
  #
  #     rdr-anchor "packetthief"
  #
  # in /etc/pf.conf in the "Translation" section of /etc/pf.conf. We can then
  # use the ioctl with DIOCNATLOOK approach that Squid uses to get a
  # pfioc_natlook data structure to get the original destination of the connection.
  class PFDivert
    module PFDivertRuleHandler
      attr_accessor :active_rules

      # Executes a rule and holds onto it for later removal.
      def run(rule)
        @active_rules ||= []

#        args = ['pfctl', 'add', 'set', '30'] # TODO: make the rule number customizable
        args = ['echo']

        @active_rules << rule
        args << @active_rules.map { |r| r.to_pf_command.join(" ") }.join("\n")

        args = args + %w{| pfctl -a packetthief -f -}

        # run the command
        unless system(*args)
          raise "Command #{args.inspect} exited with error code #{$?.inspect}"
        end

      end

      # Reverts all executed rules that this handler knows about.
      def revert
        return if @active_rules == nil or @active_rules.empty?

          args = %W{pfctl -a packetthief -F rules}
          unless system(*args)
            raise "Command #{args.inspect} exited with error code #{$?.inspect}"
          end
#        end

        @active_rules = []
      end
    end
    extend PFDivertRuleHandler

    class PFDivertRule < RedirectRule

      attr_accessor :rule_number

      def initialize(handler, rule_number=nil)
        super(handler)
        @rule_number = rule_number
      end

      def to_pf_command
        args = []

        args << "pass" << "in"

        if self.rulespec
          args << 'on' << self.rulespec[:in_interface].to_s if self.rulespec.has_key? :in_interface

          args << "proto" << self.rulespec.fetch(:protocol,'ip').to_s

          args << 'from'
          args << self.rulespec.fetch(:source_address, 'any').to_s
          args << 'port' << self.rulespec[:source_port].to_s if self.rulespec.has_key? :source_port

          args << 'to'
          args << self.rulespec.fetch(:dest_address, 'any').to_s
          args << 'port' << self.rulespec[:dest_port].to_s if self.rulespec.has_key? :dest_port
        end

        if self.redirectspec
          if self.redirectspec.has_key? :to_ports
            args << 'divert-to'
            args << "127.0.0.1"
            args << 'port' << self.redirectspec[:to_ports].to_s if self.redirectspec.has_key? :to_ports
          else
            raise "Rule lacks a valid redirect: #{self.inspect}"
          end
        end


        args
      end
    end

    def self.redirect(args={})
      rule = PFDivertRule.new(self)
      rule.redirect(args)
    end

    # Returns the [port, host] for the original destination of +sock+.
    #
    # +Sock+ can be a Ruby socket or an EventMachine::Connection (including
    # handler modules, which are mixed in to an anonymous descendent of
    # EM::Connection).
    #
    # When PF uses a divert-to[1] rule to redirect a connection to a local socket,
    # the destination address remains unchanged, meaning that C's getsockname()
    # will return the original destination.
    # [1]: http://www.openbsd.org/cgi-bin/man.cgi?query=pf.conf&sektion=5&arch=&apropos=0&manpath=OpenBSD+Current
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
