require 'openssl'

module PacketThief
  module EMHandlers

    # Preliminary SSL Transparent Proxy.
    #
    #
    #   EM.run {
    #     SSLInterceptor.start 'localhost', 54321 do |p|
    #       p.ctx.
    #     end
    #   }
    #
    # Note: During #initialize and #post_init, the SSLInterceptor class
    # does not have access to its socket yet. Instead, use #tls_pre_start or
    # the code block you pass to .start to initialize the SSLContext, and use
    # #tls_post_accept to do anything once the SSL handshake has completed. You
    # can also override #servername_cb to perform the SNI callback.
    class SSLInterceptor < ::EM::Connection
      attr_accessor :fd
      attr_accessor :ctx
      attr_accessor :tcpsocket
      attr_accessor :sslsocket

      # Handles the initial listening socket. We can't seem to use
      # EM.start_server -> EM.detach -> em.watch without triggering
      # (in EventMachine 1.0.0):
      #
      #   Assertion failed: (sd != INVALID_SOCKET), function _RunSelectOnce, file em.cpp, line 893.
      #
      # So we handle the server muckery ourselves.
      module InitialServer
        def initialize(servsocket, ssl_class, args, blk)
          @servsocket = servsocket
          @ssl_class = ssl_class
          @args = args
          @blk = blk
        end

        def notify_readable
          puts "InitialServer: Received a new connection, spawning a #{@ssl_class}"
          sock = @servsocket.accept_nonblock

          ::EM.watch sock, @ssl_class, *@args do |h|
            h.notify_readable = true
#            h.notify_writable = true
            h.tcpsocket = sock
            # Now call custom setup for the context.
            h.tls_pre_start
            @blk.call(h)
            # And finally finish initialization by applying the context to an
            # SSLSocket, and setting the internal state.
            h.tls_begin
          end

        end

        def notify_writable
          puts "server socket notify writable"
        end
      end

      def self.start(host, port, *args, &block)
        ssl_class = self

        serv = TCPServer.new host, port

        # We use InitialServer to listen for incoming connections. It will then
        # create the actual SSLInterceptor.
        ::EM.watch serv, InitialServer, serv, ssl_class, args, block do |h|
          h.notify_readable = true
          h.notify_writable = true
        end
      end

      def initialize
        puts "ssl initialize"
      end

      def post_init
        puts "ssl post_init"
        # Set up initial values
        @ctx = OpenSSL::SSL::SSLContext.new
        @ctx.servername_cb = proc {|sslsocket, hostname| self.servername_cb(sslsocket, hostname) }
      end

      def tls_begin
        @sslsocket = OpenSSL::SSL::SSLSocket.new(@tcpsocket, @ctx)
        @state = :initialized
      end


      def notify_readable
        puts "notify_readable"
        attempt_accept if @ssl_state == :initialized
        case @state
        when :initialized
          attempt_accept
        when :ready_to_read
          attempt_read
        when :write_needs_to_read
          attempt_write
        end
      end

    # We only care about notify_writable if we are waiting to write for some
    # reason.
      def notify_writable
        attempt_accept if @ssl_state == :need_to_write
        puts "received notify_writable"
        case @state
        when :initialized
          attempt_accept
        when :read_needs_to_write
          attempt_read
        when :write_needs_to_write
          attempt_write
        end
      end

      def attempt_accept
        begin
          @sslsocket.accept_nonblock
          @state = :ready_to_read
          notify_writable = false
          tls_post_accept
        rescue IO::WaitReadable
          # accept_nonblock needs to wait until it can read again.
          notify_readable = true
        rescue IO::WaitWritable
          # accept_nonblock needs to wait until it can write again.
          notify_writable = true
        rescue OpenSSL::SSL::SSLError => e
          # ssl handshake failed. Likely due to client rejecting our certificate!
          tls_failed_accept(e)
          handle_close
        end
      end

      def attempt_read
        begin
          data = @sslsocket.read_nonblock 4096 # much more than a network packet...
          tls_client_recv(data)
          notify_writable = false
        rescue EOFError
          # remote closed. time to wrap up
          handle_close
        rescue IO::WaitReadable
          # we had no data to read.
          notify_readable = true
        rescue IO::WaitWritable
          # we ran out of buffer to send (yes, SSLSocket#read_nonblock can
          # trigger this)
          @state = :read_needs_to_write
        else
          @state = :ready_to_read
        end
      end

      def attempt_write(data=nil)
        @write_buf ||= ""
        @write_buf << data if data
        begin
          count_written = @sslsocket.write_nonblock @write_buf
        rescue IO::WaitWritable
          notify_writable = true
        rescue IO::WaitReadable
          @state = :write_needs_to_read
        else
          # if we didn't write everything
          if count_written < @write_buf.bytesize
            # shrink the buf
            # byteslice was added in ruby 1.9.x. in ruby 1.8.7, bytesize is aliased to length
            @write_buf = @write_buf.respond_to?(:byteslice) ? @write_buf.byteslice(count_written..-1) : @write_buf.slice(count_written..-1)
            # and wait for writable.
            notify_writable = true
          else
            # successful write, so don't need to wait for writable.
            notify_writable = false
          end
        end
      end

      def handle_close
          tls_unbind
          detach
          @sslsocket.close
          @tcpsocket.close
      end

      # Override this if you want to manipulate the SSLContext or anything else before the SSLSocket is created.
      def tls_pre_start
      end

      # Called right after SSLSocket#accept_nonblock succeeds.
      def tls_post_accept
        puts "Accepted!"
      end

      # Called right after accept_nonblock fails for some unknown reason. The
      # only parameter contains the OpenSSL::SSL::SSLError object that was
      # thrown.
      #
      # The connection will be closed after this.
      def tls_failed_accept(e)
        puts "Failed to accept: #{e.inspect}"
      end

      # Called when the client sends a hostname using the SNI TLS extension.
      #
      # This method should return an OpenSSL::SSL::SSLContext. It gives you an
      # opportunity to pick or generate a different server certificate or
      # certificate chain based on the hostname requested by the client.
      #
      # The default implementation does nothing by just returning the original
      # SSLContext.
      def servername_cb(sslsock, hostname)
        sslsock.context
      end

      def send_to_client(data)
        # buffer the data and send some if possible.
      end

      def send_to_dest(data)
        # TODO: enable remote ssl.
      end


      def tls_client_recv (data)
        puts "tls_client_recv: #{data}"
      end

      def tls_client_send
      end

      def tls_unbind
        puts "tls unbind"
      end


    end
  end
end
#        @ctx.ca_file
#        @ctx.ca_path
#        @ctx.cert
#        @ctx.cert_store
#        @ctx.client_ca
#        @ctx.extra_chain_cert
#        @ctx.key
#        @ctx.options

