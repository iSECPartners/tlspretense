#!/usr/bin/env ruby

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root

PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 80, :in_interface => 'en1').run

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

  EM.start_server('127.0.0.1', 54321, PacketThief::EM::ProxyRedirector, 'localhost', 8080)

end
PacketThief.revert
