module PacketThief
  module Handlers

    # Provides a transparent proxy for any TCP connection.
    class SSLTransparentProxy < SSLServer

      # Represents a connection out to the original destination.
      class SSLProxyConnection < SSLClient
        # Boolean that represents whether this handler has started to
        # close/unbind. Used to ensure there is no unbind-loop between the two
        # connections that make up the proxy.
        attr_accessor :closed

        # Boolean that represents whether the connection has connected yet.
        attr_accessor :connected

        # Sets up references to the client proxy connection handler that created
        # this handler.
        def initialize(tcpsocket, client_conn, ctx)
          super(tcpsocket)
          @client = client_conn
          @ctx = ctx

          @connected = false
          @closed = false
          @tls_hostname = @client.dest_hostname if @client.dest_hostname
        end

        # send on successful handshake instead of on post_init.
        def tls_successful_handshake
          @client.dest_connected
          @client._send_buffer
        end

        def tls_failed_handshake(e)
          @client.dest_handshake_failed(e)
        end

        # Transmit data sent by the destinaton to the client.
        def receive_data(data)
          @client.dest_recv(data)
        end

        # Start the closing process and close the other connection if it is not
        # already closing.
        def unbind
          @client.dest_closed
          self.closed = true
          @client.dest = nil
          @client.close_connection_after_writing if @client and not @client.closed
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
      attr_accessor :closed

      # If a client specifies a TLS hostname extension (SNI) as the hostname,
      # then we can forward that fact on to the real server. We can also use it
      # to choose a certificate to present.
      attr_accessor :dest_hostname

      # The SSLContext that will be used on the connection to the destination.
      # Initially, its verify_mode is set to OpenSSL::SSL::VERIFY_NONE.
      attr_accessor :dest_ctx

      def initialize(tcpsocket)
        super
        @closed = false

        @client = self
        @dest = nil

        @buffer = []
        @@activeconns ||= {}

        @client_port, @client_host = Socket.unpack_sockaddr_in(get_peername)
        @dest_port, @dest_host = PacketThief.original_dest(self)

        if @@activeconns.has_key? "#{client_host}:#{client_port}"
          puts "Warning: loop detected! Stopping the loop."
          close_connection
          return
        end

        @dest_ctx = OpenSSL::SSL::SSLContext.new
        @dest_ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

      end

      # Just calls client_connected to keep things straightforward.
      def tls_successful_handshake
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
        self.closed = true
#        @dest.client = nil if @dest
        @dest.close_connection_after_writing if @dest and not @dest.closed
      end

      # Initiate the connection to @dest_host:@dest_port.
      def connect_to_dest
        return if @dest
        @dest = SSLProxyConnection.connect(@dest_host, @dest_port, self, @dest_ctx)
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
        @buffer << data
        _send_buffer if @dest
      end

      # Sends data back to the client
      def send_to_client(data)
        send_data data
      end

      # Returns the certificate chain for the destination, or nil if the
      # destination connection does not exist yet.
      def dest_cert_chain
        return @dest.sslsocket.peer_cert_chain if @dest
        nil
      end

      #### Callbacks

      # Set _dest_hostname_ in addition to the default behavior.
      def servername_cb(sslsock, hostname)
        @dest_hostname = hostname

        super(sslsock, hostname)
      end

      # This method is called when a client connects, and the TLS handhsake has
      # completed. The default behavior is to begin initating the connection to
      # the original destination. Override this method to change its behavior.
      def client_connected
        connect_to_dest
      end

      # This method is called when the TLS handshake between the client and the
      # proxy fails. It does nothing by default.
      def client_handshake_failed
      end

      # This method is called when the proxy receives data from the client
      # connection. The default behavior is to call send_to_dest(data) in order
      # to foward the data on to the original destination. Override this method
      # to analyze the data, or modify it before sending it on.
      def client_recv(data)
        send_to_dest data
      end

      # Called when the client connection closes. At present, it only provides
      # informational utility.
      def client_closed
      end

      # Called when the connection to and the TLS handshake between the proxy
      # and the destination succeeds. The default behavior does nothing.
      def dest_connected
      end

      # Called when the TLS handshake between the proxy and the destination
      # fails.
      def dest_handshake_failed(e)
      end

      # Called when the proxy receives data from the destination connection.
      # The default behavior calls #dest_recv() to send the data to the client.
      #
      # Override it to analyze or modify the data.
      def dest_recv(data)
        send_to_client data
      end

      # Called when the original destination connection closes. At present, it only provides
      # informational utility.
      def dest_closed
      end

    end

  end
end
