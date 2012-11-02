

module PacketThief
  module Impl
    # Implementation that uses PF's +rdr+ (old style rules) and parses pfctl's
    # output to interoperate with Mac OS X 10.7 Lion.
    #
    # It assumes that the system running PacketThief is already set up to
    # reroute traffic like a NAT (On Mac OS X, you can do this by enabling
    # Internet Sharing).
    #
    # To use it, you need to add the following rule to your /etc/pf.conf file
    # in the "Translation" section.
    #
    #     rdr-anchor "packetthief"
    #
    # This rule probably should be inserted after any NAT rules, but before any
    # other redirect rules (such as Apple's +rdr-anchor+ rule). Once you have
    # added it, you can reload the core ruleset:
    #
    #     pfctl -f /etc/pf.conf
    #
    # == Design
    #
    # Lion (and Mountain Lion) provide an older implementation of PF (circa
    # OpenBSD 4.3 and earlier) that does not contain the +divert-to+ action.
    # Furthermore, Apple has decided to not make pfvars.h a public header file,
    # making it marginally difficult to compile C code that can look up the
    # original destination. Instead, we use pfctl to look up the state table,
    # and we parse its output to find the current connection and acquire its
    # original destination.
    #
    # Redirect rules look like the following:
    #
    #     rdr on en1 proto tcp from any to any port 443 -> 127.0.0.1 port 54321
    #
    # The pfctl state table output looks something like:
    #
    #     $ sudo pfctl -s states
    #     No ALTQ support in kernel
    #     ALTQ related functions disabled
    #     ALL tcp 74.125.224.68:80 <- 192.168.2.2:52995       ESTABLISHED:ESTABLISHED
    #     ALL tcp 192.168.2.2:52995 -> 10.0.1.2:33596 -> 74.125.224.68:80       ESTABLISHED:ESTABLISHED
    #     ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:52998       CLOSED:SYN_SENT
    #     ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:52999       CLOSED:SYN_SENT
    #     ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:53000       CLOSED:SYN_SENT
    #     ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:53001       CLOSED:SYN_SENT
    #     ALL udp 192.168.2.1:53 <- 192.168.2.2:53690       SINGLE:MULTIPLE
    #     ALL tcp 74.125.224.105:80 <- 192.168.2.2:53002       ESTABLISHED:ESTABLISHED
    #     ALL tcp 192.168.2.2:53002 -> 10.0.1.2:38466 -> 74.125.224.105:80       ESTABLISHED:ESTABLISHED
    #     ALL udp 224.0.0.251:5353 <- 10.0.1.4:5353       NO_TRAFFIC:SINGLE
    #     ALL udp ff02::fb[5353] <- fe80::72de:e2ff:fe41:5ddd[5353]       NO_TRAFFIC:SINGLE
    #
    #  /^(?<iface>\S+)\s+(?<proto>\S+)\s+(?<dest>\S+)\s+<-\s+(?<origdest>\S+)\s+<-\s+(?<src>\S+)\s+(?<status>\S+)$/
    #
    class PFRdr
      module PFRdrRuleHandler
        include Logging
        attr_accessor :active_rules

        # Executes a rule and holds onto it for later removal.
        def run(rule)
          @active_rules ||= []

          @active_rules << rule
          rulestrs = @active_rules.map { |r| r.to_pf_command.join(" ") }

          rulestrs.each { |rule| logdebug rule }
          args = %W{pfctl -q -a packetthief -f -}
          IO.popen(args, "w+") do |pfctlio|
            rulestrs.each { |rule| pfctlio.puts rule }
          end
          unless $?.exitstatus == 0
            raise "Command #{args.inspect} exited with error code #{$?.inspect}"
          end

        end

        # Reverts all executed rules that this handler knows about.
        def revert
          return if @active_rules == nil or @active_rules.empty?

          args = %W{pfctl -q -a packetthief -F all}
          unless system(*args)
            raise "Command #{args.inspect} exited with error code #{$?.inspect}"
          end
          #        end

          @active_rules = []
        end
      end
      extend PFRdrRuleHandler

      class PFRdrRule < RedirectRule

        attr_accessor :rule_number

        def initialize(handler, rule_number=nil)
          super(handler)
          @rule_number = rule_number
        end

        def to_pf_command
          args = []

          args << "rdr"

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
              args << '->'
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
        rule = PFRdrRule.new(self)
        rule.redirect(args)
      end

      RDR_PAT = /^(?<iface>\S+)\s+(?<proto>\S+)\s+(?<dest>\S+)\s+<-\s+(?<origdest>\S+)\s+<-\s+(?<src>\S+)\s+(?<status>\S+)$/

      # Returns the [port, host] for the original destination of +sock+.
      #
      # +Sock+ can be a Ruby socket or an EventMachine::Connection (including
      # handler modules, which are mixed in to an anonymous descendent of
      # EM::Connection).
      #
      # When PF uses a nat/rdr rule, it stores the original destination in a
      # table that can be queried using an ioctl() call on the /dev/pf device.
      # Unfortunately for Mac OS X 10.7 and 10.8, Apple does not provide the
      # necessary pfvars.h header for querying pf, although it exists in the XNU
      # kernel source, which marks it as a "private" header. Apple's version is
      # also "different" from the version supported by most BSDs these days,
      # creating additional headaches.
      #
      # To work around this, we instead use +pfctl -s states+ to get the nat
      # state information.
      def self.original_dest(sock)
        if sock.respond_to? :getsockname
          sockname = sock.getsockname
        elsif sock.respond_to? :get_sockname
          sockname = sock.get_sockname
        else
          raise ArgumentError, "#{sock.inspect} supports neither :getsockname nor :get_sockname!"
        end
        if sock.respond_to? :getpeername
          peername = sock.getpeername
        elsif sock.respond_to? :get_peername
          peername = sock.get_peername
        else
          raise ArgumentError, "#{sock.inspect} supports neither :getpeername nor :get_peername!"
        end
        dest = Socket.unpack_sockaddr_in(sockname)
        src = Socket.unpack_sockaddr_in(peername)

        state_table = `pfctl -q -s state`
        rdr_lines = state_table.split("\n").map { |l| l.match(RDR_PAT) }.compact
        matched_conns = rdr_lines.select { |l| l[:dest] == "#{dest[1]}:#{dest[0]}" and l[:src] == "#{src[1]}:#{src[0]}" }
        raise "multiple conns matched: #{matched_conns.inspect}" unless matched_conns.length == 1
        host, port = matched_conns[0][:origdest].split(':', 2)
        port = port.to_i

        logdebug "original_dest:", :port => port, :host => host
        [port, host]
      end

    end

  end
end
