#!/usr/bin/env ruby

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root

class VerboseProxy < PacketThief::EM::SSLSmartProxy

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
    puts "#{client_desc} says (#{data.length}): #{data.inspect}"
#    @seenclientdata ||= false
#    unless @seenclientdata
#      puts "#{client_desc} says (#{data.length}): #{data.split("\r\n\r\n",2)[0]}"
#      puts ""
#      @seenclientdata = true
#    else
#      puts "#{client_desc} says (#{data.length}): #{data[0,20].inspect}"
#    end
    super(data)
  end

  def client_closed
    puts "#{client_desc} closed"
  end

  def dest_connected
    puts "#{dest_desc} connected"
    puts "Remote certificates: #{dest_cert_chain.inspect}"
  end

  def dest_handshake_failed(e)
    puts "TLS handshake to #{dest_desc} handshake failed: #{e}"
  end

  def dest_recv(data)
    puts "#{dest_desc} says (#{data.length}): #{data.inspect}"
#    @seendestdata ||= false
#    unless @seendestdata
#      puts "#{dest_desc} says (#{data.length}): #{data.split("\r\n\r\n",2)[0]}"
#      puts ""
#      @seendestdata = true
#    else
#      puts "#{dest_desc} says (#{data.length}): #{data[0,20].inspect}"
#    end
    super(data)
  end

  def dest_closed
    puts "#{dest_desc} closed"
  end

end

if ARGV.length != 2
  puts "script cacert.pem keypem"
  exit 1
end
cacert = OpenSSL::X509::Certificate.new(File.read(ARGV[0]))
key = OpenSSL::PKey.read(File.read(ARGV[1]))


PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'en1').run
#PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'vmnet1').run
#PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'vmnet8').run
#PacketThief.redirect(:to_ports => 54322).where(:protocol => :tcp, :dest_port => 80, :in_interface => 'en1').run

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

  VerboseProxy.start('127.0.0.1', 54321, cacert, key) do |h|
#    h.ctx.ssl_version = :TLSv1_server
  end
  EM.start_server('127.0.0.1', 54322, PacketThief::EM::TransparentProxy) do |h|
    def h.client_recv(data)
      puts "HTTP: #{data}"
    end
  end

end
PacketThief.revert
