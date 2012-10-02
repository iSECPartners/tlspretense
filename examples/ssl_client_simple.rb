#!/usr/bin/env ruby
# This example just shows how to call the SSLServer class with PacketThief. All
# it does is receive data -- it does not attempt to send data on.

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root


EM.run do

  PacketThief::EM::SSLClient.connect('www.isecpartners.com', 443) do |h|
    h.ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    h.ctx.ssl_version = :TLSv1_client

    def h.tls_successful_handshake
      puts @sslsocket.peer_cert_chain.inspect
    end
  end

end
