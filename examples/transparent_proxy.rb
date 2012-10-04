#!/usr/bin/env ruby

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root

PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 80, :in_interface => 'en1').run
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

class VerboseProxy < PacketThief::Handlers::TransparentProxy

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

EM.run do

  EM.start_server('127.0.0.1', 54321, VerboseProxy)

end
PacketThief.revert
