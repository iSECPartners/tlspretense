module PacketThief
  module Handlers

    # Provides a transparent proxy for any TCP connection.
    class TransparentProxy < ::EM::Connection
      include Logging

      # Represents a connection out to the original destination.
      module ProxyConnection
        # Boolean that represents whether this handler has started to
        # close/unbind. Used to ensure there is no unbind-loop between the two
        # connections that make up the proxy.
        attr_accessor :closing

        # Boolean that represents whether the connection has connected yet.
        attr_accessor :connected

        # Sets up references to the client proxy connection handler that created
        # this handler.
        def initialize(client_conn)
          @client = client_conn

          @connected = false
          @closing = false
        end

        def post_init
          @client._send_buffer
        end

        # Transmit data sent by the destinaton to the client.
        def receive_data(data)
          @client.dest_recv(data)
        end

        # Start the closing process and close the other connection if it is not
        # already closing.
        def unbind
          @client.dest_closed
          self.closing = true
          @client.close_connection_after_writing if @client and not @client.closing
        end

      end

      # This holds a reference to the connection to the destination. If it is
      # null, it hasn't been created yet.
      attr_accessor :dest

      # This holds a reference to the connection to the client. It is actually
      # self.
      attr_accessor :client

      attr_reader :client_host, :client_port

      # Override these before connecting to dest to change the dest connection.
      attr_accessor :dest_host, :dest_port

      # An internal buffer of packet data received from the client. It will grow until
      # the destination connection connects.
      attr_accessor :buffer

      # Boolean that represents whether this handler has started to
      # close/unbind. Used to ensure there is no unbind-loop between the two
      # connections that make up the proxy.
      attr_accessor :closing

      # When the proxy should connect to a destination.
      attr_accessor :when_to_connect_to_dest

      def initialize
      end

      def post_init
        @closing = false

        @client = self
        @dest = nil

        @buffer = []
        @@activeconns ||= {}

        @client_port, @client_host = Socket.unpack_sockaddr_in(get_peername)
        @dest_port, @dest_host = PacketThief.original_dest(self)

        logdebug "Client connected", :client_host => client_host, :client => "#{@client_host}:#{@client_port}", :orig_dest => "#{@dest_host}:#{@dest_port}"

        if @@activeconns.has_key? "#{client_host}:#{client_port}"
          puts "Warning: loop detected! Stopping the loop."
          close_connection
          return
        end

        client_connected
      end

      def receive_data(data)
        client_recv data
      end

      # Start the closing process and close the other connection if it is not
      # already closing.
      def unbind
        client_closed
        @@activeconns.delete "#{client_host}:#{client_port}"
        self.closing = true
        @dest.close_connection_after_writing if @dest and not @dest.closing
      end


      # Initiate the connection to @dest_host:@dest_port.
      def connect_to_dest
        logdebug "Connecting to #{@dest_host}:#{@dest_port}"
        @dest = ::EM.connect(@dest_host, @dest_port, ProxyConnection, self)
        newport, newhost = Socket::unpack_sockaddr_in(@dest.get_sockname)
        # Add the new connection to the list to prevent loops.
        @@activeconns["#{newhost}:#{newport}"] = "#{dest_host}:#{dest_port}"
      end

      def _send_buffer
        @buffer.each do |pkt|
          @dest.send_data pkt
        end
        @buffer = []
      end


      # Queues up data to send to the remote host, only sending it if the
      # connection to the remote host exists.
      def send_to_dest(data)
        logdebug "sending to dest", :data => data
        @buffer << data
        _send_buffer if @dest
      end

      # Sends data back to the client
      def send_to_client(data)
        send_data data
      end


      # This method is called when a client connects. The default behavior is
      # to begin initating the connection to the original destination. Override
      # this method to change its behavior.
      def client_connected
        connect_to_dest
      end

      # This method is called when the proxy receives data from the client
      # connection. The default behavior is to call send_to_dest(data) in order
      # to foward the data on to the original destination. Override this method
      # to analyze the data, or modify it before sending it on.
      def client_recv(data)
        logdebug("received from client", :data => data)
        send_to_dest data
      end

      # Called when the proxy receives data from the destination connection.
      # The default behavior calls #dest_recv() to send the data to the client.
      #
      # Override it to analyze or modify the data.
      def dest_recv(data)
        logdebug("received from dest", :data => data)
        send_to_client data
      end

      # Called when the client connection closes. At present, it only provides
      # informational utility.
      def client_closed
        logdebug("client closed connection")
      end

      # Called when the original destination connection closes. At present, it only provides
      # informational utility.
      def dest_closed
        logdebug("dest closed connection")
      end

    end

  end
end
