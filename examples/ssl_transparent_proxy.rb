#!/usr/bin/env ruby

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root

#PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 80, :in_interface => 'en1').run
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

class VerboseProxy < PacketThief::EM::SSLTransparentProxy

  def client_connected
    puts "Client #{client_host}:#{client_port}->#{dest_host}:#{dest_port} connected"
    connect_to_dest
  end

  def client_recv(data)
    puts "Client #{client_host}:#{client_port}->#{dest_host}:#{dest_port} says: #{data[0,20].inspect}"
    send_to_dest data
  end

  def dest_recv(data)
    puts "Dest #{client_host}:#{client_port}->#{dest_host}:#{dest_port} says: #{data[0,20].inspect}"
    send_to_client data
  end

  def client_closed
    puts "Client #{client_host}:#{client_port}->#{dest_host}:#{dest_port} closing"
  end

  def dest_closed
    puts "Dest #{client_host}:#{client_port}->#{dest_host}:#{dest_port} closing"
  end

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

  VerboseProxy.start('127.0.0.1', 54321) do |h|
    h.ctx.cert = cert
    h.ctx.extra_chain_cert = chain
    h.ctx.key = OpenSSL::PKey.read(File.read('key.pem'))
    h.ctx.ssl_version = :TLSv1_server
  end

end
PacketThief.revert
