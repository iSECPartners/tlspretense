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

class VerboseProxy < PacketThief::Handlers::SSLTransparentProxy

  def client_desc
    "Client #{client_host}:#{client_port}->#{dest_host}:#{dest_port} (#{dest_hostname})"
  end

  def dest_desc
    "Dest #{dest_host}:#{dest_port}(#{dest_hostname})->#{client_host}:#{client_port}"
  end

  def servername_cb(sslsock, hostname)
    puts "#{client_desc} request hostname: #{hostname}"
    super(sslsock, hostname)
  end

  def client_connected
    puts "#{client_desc} connected and TLS handshake succeeded"
    super
  end

  def client_handshake_failed(e)
    puts "TLS handshake from #{client_desc} failed: #{e}"
  end

  def client_recv(data)
    puts "#{client_desc} says: #{data[0,20].inspect}"
    super(data)
  end

  def client_closed
    puts "#{client_desc} closing"
  end

  def dest_connected
    puts "#{dest_desc} connected"
    puts "Remote certificates: #{dest_cert_chain.inspect}"
  end

  def dest_handshake_failed(e)
    puts "TLS handshake to #{dest_desc} handshake failed: #{e}"
  end

  def dest_recv(data)
    puts "#{dest_desc} says: #{data[0,20].inspect}"
    super(data)
  end

  def dest_closed
    puts "#{dest_desc} closing"
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
