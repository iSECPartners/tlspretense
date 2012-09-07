#!/usr/bin/env ruby

$: << 'lib'

require 'rubygems'
require 'eventmachine'
require 'packetthief' # needs root

# Represents a connection out to the original destination.
module ProxyConnection
  attr_accessor :closing

  def initialize(client_conn)
    @closing = false
    @client_conn = client_conn
    @client_conn.dest_conn = self
    puts "#{self.inspect} ProxyConnection#initialize"
  end

  def post_init
    puts "#{self.inspect} ProxyConnection#post_init"
  end

  def connection_completed
    puts "#{self.inspect} ProxyConnection#connection_completed. Sending buffer"
    send_data @client_conn.buffer
    @client_conn.buffer = ""
  end

  def receive_data(data)
    puts "#{self.inspect} recv: #{data.inspect}"
    @client_conn.send_data data
  end

  def unbind
    puts "#{self.inspect} destination closed its connection!"
    self.closing = true
    @client_conn.close_connection_after_writing if @client_conn and not @client_conn.closing
  end

end

# Provides a transparent proxy for any TCP connection.
class TransparentProxy < EM::Connection
  attr_accessor :dest_conn
  attr_accessor :buffer
  attr_accessor :closing

  def initialize
    @closing = false
    @dest_conn = nil
    @buffer ||= ""
  end

  def post_init
    puts "#{self.inspect} TransparentProxy#post_init"
  end

  def connection_completed
    puts "#{self.inspect} TransparentProxy#connection_completed"
  end

  def receive_data(data)
    @dest_port, @dest_host = PacketThief.original_dest(self)
    puts "#{self.inspect} Original dest: #{@dest_host}:#{@dest_port.to_s}"
    @buffer << data
    puts "#{self.inspect} send: #{data.inspect}"
    if @dest_conn == nil
      puts "#{self.inspect} opening a connection to #{@dest_host}:#{@dest_port.to_s}"
      EM.connect(@dest_host, @dest_port, ProxyConnection, self)
    else
      @dest_conn.send_data @buffer
      @buffer = ""
    end
  end

  def unbind
    puts "#{self.inspect} closing"
    puts "    but @dest_con is nil" if @dest_con == nil
    self.closing = true
    @dest_conn.close_connection_after_writing if @dest_conn and not @dest_conn.closing
  end

end

PacketThief.redirect(:to_ports => 54321).where(:protocol => :tcp, :dest_port => 80).run
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

EM.run {
  EM.start_server('127.0.0.1', 54321, TransparentProxy)
}
PacketThief.revert
