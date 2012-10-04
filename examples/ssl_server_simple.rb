#!/usr/bin/env ruby
# This example just shows how to call the SSLServer class with PacketThief. All
# it does is receive data -- it does not attempt to send data on.

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root

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

def split_chain(raw)
  chain = []
  remaining = raw
  certpat = /-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----/m
  while m = certpat.match(remaining)
    remaining = m.post_match
    chain << m[0].strip
  end
  chain
end

raw = File.read("chain.pem")
rawchain = split_chain(raw)
chain = rawchain.map { |rawcert| OpenSSL::X509::Certificate.new(rawcert) }
cert = chain.shift

EM.run do

  PacketThief::Handlers::SSLServer.start('127.0.0.1', 54321) do |h|
    puts "extra block"
    h.ctx.cert = cert
    h.ctx.extra_chain_cert = chain
    h.ctx.key = OpenSSL::PKey.read(File.read('key.pem'))
  end


end
PacketThief.revert
