require 'socket'
require 'eventmachine'

module PacketThief
  autoload :RedirectRule, 'packetthief/redirect_rule'
  autoload :Netfilter, 'packetthief/netfilter'
  autoload :Ipfw, 'packetthief/ipfw'
  autoload :PF,           'packetthief/pf'

  autoload :Handlers, 'packetthief/handlers'
  autoload :Util, 'packetthief/util'

  def self.method_missing(m, *args, &block)
    case RUBY_PLATFORM
    when /linux/
      Netfilter.send(m, *args, &block)
    when /darwin10/ # Mac OS X 10.6 and earlier.
      Ipfw.send(m, *args, &block)
    else
      raise "Platform #{RUBY_PLATFORM} not yet supported! If you know your network implementation, call it directly."
    end
  end

end
