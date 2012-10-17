require 'socket'
require 'logger'

require 'eventmachine'

# Framework for intercepting packets, redirecting them to a handler, and doing
# something with the "stolen" connection.
#
# == Description
#
# PacketThief is a little Ruby framework for programatically intercepting network
# traffic. It provides an abstraction around configuring various OS firewalls and
# for gathering information about the original connection, and it offers several
# sample handler classes (for use with EventMachine) for intercepting and
# forwarding traffic. If you want a full fledged security tool for intercepting
# and analyzing network traffic, check out
# {Mallory}[http://intrepidusgroup.com/insight/mallory/] instead.
#
# PacketThief is currently intended to be run on a computer that should be
# configured as the gateway for whatever network traffic you wish to intercept.
# You then use PacketThief to configure your OS firewall and network routing to
# send specified network traffic to a socket. The socket handling code can then
# read the data, modify it, send it on to the original destination (although the
# new connection will originate from the gateway), etc.
#
# Currently, PacketThief supports basic redirection using Ipfw (Mac OS X, BSD)
# and Netfilter (Linux). It also more than likely requires your PacketThief-based
# script to be run as root in order to modify your system's firewall.
#
# == Usage
#
# First, you must configure the system that will run PacketThief to be able to
# intercept network traffic. If that host system has two network interfaces (such
# as a laptop with ethernet and wifi), then you can turn the system into a router
# by configure one interface to be an external interface that can communicate
# with your main network and the Internet, and the other interface can be
# configured as the gateway for one or more devices/client systems that you would
# like to test.
#
# NATing multiple network interfaces can be easily done in Mac OS X by enabling
# Internet Sharing in the Sharing System Preference pane, which will also let you
# configure your wifi to be a wireless access point. For Linux, take a look at
# the +examples/setup_iptables.sh+ script, or {search the Internet for tutorials
# on various ways to set up Mallory}[https://bitbucket.org/IntrepidusGroup/mallory/wiki/Home].
#
# Basic use:
#
#     require 'packetthief'
#     # redirect tcp traffic destined for port 443 to localhost port 65432:
#     PacketThief.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
#     at_exit { PacketThief.revert } # Remove our firewall rules when we exit
#
# This will set up Firewall/routing rules to redirect packets matching the .where
# clause to the localhost port specified by the redirect() clause. The
# Kernel#at_exit handler calls the .revert method which will remove the firewall
# rules added by PacketThief.
#
# You can then capture network traffic in your script by opening a listening
# socket your +:to_ports+ destination. When you create the socket, set the
# hostname to a blank string to have it listen on all interfaces -- this winds up
# being more compatible with different firewalls.
#
# Using a TCPServer:
#
#     TCPServer.new('', 65432)
#
# or (untested):
#
#     TCPServer.new(65432)
#
# Using EventMachine:
#
#     EM.run {
#         start_server '', 65432, MyHandler
#     }
#
#
# In your listener code you can recover the original destination by passing in an
# accepted socket or an EventMachine::Connection-based handler.
#
#     PacketThief.original_dest(socket_or_em_connection)
#
# PacketThief also provides several EventMachine handlers to help build
# interceptors. For example, PacketThief::Handlers::TransparentProxy provides a
# class that allows you to view or mangle arbitrary TCP traffic before passing it
# on to the original destination. The package also includes several handlers for
# dealing with SSL-based traffic. Unlike EventMachine's built-in SSL support
# (#start_tls), PacketThief::Handlers::SSLClient and
# PacketThief::Handlers::SSLServer give you direct access to the
# OpenSSL::SSL::SSLContext to configure certificates and callbacks, and
# PacketThief::Handlers::SSLSmartProxy will connect to the original destination
# in order to acquire its host certificate, which it then modifies for use with a
# configured CA. See the documentation and the example directory for more
# information.
#
# == Mac OS X Setup example
#
# * Share your wifi over your ethernet. Mac OS X will run natd with your wifi as the lan.
# * Connect a mobile or wifi device to this wifi.
# * Run your PacketThief code, and specify `:in_interface => 'en1'` (assuming
#   your Airport/wifi is on en1) in the .where clause. The specified :to_ports
#   port should start receiving incoming TCP connections.
#
# Note that connections initiated both on the Mac and on any device from the
# network will hit your socket. In the future, you will be able to narrow down
# what traffic is caught.
#
module PacketThief
  autoload :RedirectRule, 'packetthief/redirect_rule'
  autoload :Impl,         'packetthief/impl'

  autoload :Handlers, 'packetthief/handlers'
  autoload :Logging,  'packetthief/logging'
  autoload :Util, 'packetthief/util'

  class << self
    include Logging
  end

  def self.implementation; @implementation ; end

  def self.implementation=(newimpl)
    logdebug "Set implementation to: #{newimpl}"
    if newimpl == nil
      @implementation = nil
    elsif newimpl.kind_of? Module
      @implementation = newimpl
    elsif
      PacketThief::Impl.constants.each do |c|
        if c.downcase.to_sym == newimpl.downcase.to_sym
          @implementation = PacketThief::Impl.const_get c
          return @implementation
        end
      end
      raise AttributeError, "Unknown implementation"
    end
  end

  def self.guess_implementation
    case RUBY_PLATFORM
    when /linux/
      Impl::Netfilter
    when /darwin(10|[0-9]($|[^0]))/ # Mac OS X 10.6 and earlier.
      Impl::Ipfw
    else
      raise "Platform #{RUBY_PLATFORM} not yet supported! If you know your network implementation, call it directly."
    end
  end

  # Pass the call on to @implementation, or an OS-specific default, if one is known.
  def self.method_missing(m, *args, &block)
    logdebug "method_missing: #{m}", :args => args, :block => block
    if @implementation == nil
      @implementation = guess_implementation
    end
    @implementation.send(m, *args, &block)
  end

end
