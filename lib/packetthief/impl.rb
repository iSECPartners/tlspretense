module PacketThief
  # PacketThief implementations. Each one contains the implementation details
  # for working with a given firewall.
  module Impl
  autoload :Netfilter,  'packetthief/impl/netfilter'
  autoload :Ipfw,       'packetthief/impl/ipfw'
  autoload :PF,         'packetthief/impl/pf'
  end
end
