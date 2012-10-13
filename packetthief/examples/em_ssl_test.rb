#!/usr/bin/env ruby

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root


# Note that this does not forward the encrypted traffic at all, so it isn't a
# full proxy. It just demonstrates that we can terminate the SSL connection
# that we have redirected.
#
# Also, you will need to supply your own certificate chain and private key file.
#
# A single connection:
#     Connected
#     starting TLS
#     Connection closed
#
# A second connection, where the client accepts the certificate:
#     Connected
#     starting TLS
#     SSL handshake completed
#     Received data
module SSLTester
  def initialize(chainfile, keyfile)
    puts "Connected"
    @chainfile = chainfile
    @keyfile = keyfile
  end

  def connection_completed
    puts "Connection completed."
  end

  def post_init
    puts "starting TLS"
    start_tls(:private_key_file => @keyfile, :cert_chain_file => @chainfile, :verify_peer => false)
  end

  def ssl_handshake_completed
    puts "SSL handshake completed"
  end

  def receive_data(data)
    puts "Received data"
  end

  def unbind
    puts "Connection closed"
  end
end


PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 443).run
EM.run {
  EM.start_server('', 54321, SSLTester, 'chain.pem', 'key.pem')

  Signal.trap("TERM") do
    puts "Received SIGTERM"
    PacketThief.revert
    exit
  end

  Signal.trap("INT") do
    puts "Received SIGINT"
    PacketThief.revert
    exit
  end

}
PacketThief.revert
