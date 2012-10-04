#!/usr/bin/env ruby
# This example just shows how to call the SSLServer class with PacketThief. All
# it does is receive data -- it does not attempt to send data on.

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root

if ARGV.length != 2
  puts "script chain.pem key.pem"
  exit 1
end

chain = PacketThief::Util.cert_chain(File.read(ARGV[0]))
puts "Certificate chain:"
p chain
cert = chain.shift
key = OpenSSL::PKey.read(File.read(ARGV[1]))

PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'en1').run
at_exit { puts "Exiting"; PacketThief.revert }
Signal.trap("TERM") do
  puts "Received SIGTERM"
  exit
end
Signal.trap("INT") do
  puts "Received SIGINT"
  exit
end

EM.run do

  PacketThief::Handlers::SSLServer.start('127.0.0.1', 54321) do |h|
    puts "extra block"
    h.ctx.cert = cert
    h.ctx.extra_chain_cert = chain
    h.ctx.key = key
  end


end
PacketThief.revert
