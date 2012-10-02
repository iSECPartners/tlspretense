require 'openssl'

module PacketThief
  module EMHandlers

    # Parent class for both SSLServer and SSLClient.
    #
    # They don't yet support #close_connection or
    # #close_connection_after_writing, get_peer_cert, get_peername, etc.
    class AbstractSSLHandler < ::EM::Connection
      attr_accessor :ctx
      attr_accessor :tcpsocket
      attr_accessor :sslsocket

      def initialize(tcpsocket)
        puts "ssl initialize"
        # Set up initial values
        @tcpsocket = tcpsocket
        @ctx = OpenSSL::SSL::SSLContext.new
      end

      # Creates _sslsocket_ from _tcpsocket_ and _ctx_, and initializes the
      # handler's internal state. Called from the class method that creates the
      # object, after post_init and the optional code block.
      def tls_begin
        @sslsocket = OpenSSL::SSL::SSLSocket.new(@tcpsocket, @ctx)
        @state = :initialized
      end

      # Calls accept_nonblock/connect_nonblock, read_nonblock, or
      # write_nonblock based on the current state of the connection.
      def notify_readable
        puts "notify_readable state: #{@state}"
        case @state
        when :initialized
          attempt_connection
        when :ready_to_read
          attempt_read
        when :write_needs_to_read
          attempt_write
        end
      end

      # We only care about notify_writable if we are waiting to write for some
      # reason.
      def notify_writable
        puts "notify_writable state: #{@state}"
        notify_writable = false # disable it now. if we still need it, we'll renabled it.
        case @state
        when :initialized
          attempt_connection
        when :read_needs_to_write
          attempt_read
        when :write_needs_to_write
          attempt_write
        end
      end

      private
      def attempt_connection
        begin
          # Client usess connect_nonblock, while server uses accept_nonblock.
          connection_action
          @state = :ready_to_read
          tls_successful_handshake
        rescue IO::WaitReadable
          # accept_nonblock needs to wait until it can read again.
          notify_readable = true
        rescue IO::WaitWritable
          # accept_nonblock needs to wait until it can write again.
          notify_writable = true
        rescue OpenSSL::SSL::SSLError => e
          # ssl handshake failed. Likely due to client rejecting our certificate!
          tls_failed_handshake(e)
          handle_close
        end
      end

      private
      def attempt_read
        begin
          data = @sslsocket.read_nonblock 4096 # much more than a network packet...
          receive_data(data)
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
          notify_writable = true
        else
          @state = :ready_to_read
        end
      end

      private
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
            #
            # byteslice was added in ruby 1.9.x. in ruby 1.8.7, bytesize is
            # aliased to length, implying that a character coresponds to a
            # byte.
            @write_buf = @write_buf.respond_to?(:byteslice) ? @write_buf.byteslice(count_written..-1) : @write_buf.slice(count_written..-1)
            # and wait for writable.
            notify_writable = true
          end
        end
      end

      private
      def handle_close
          unbind
          detach
          @sslsocket.close
          @tcpsocket.close
      end

      ####

      public

      # Call this to send data to the other end of the connection.
      def send_data(data)
        attempt_write(data)
      end


      # Note that post_init dos not have access to the _tcpsocket_
      # or the _sslsocket_. _tcpsocket gets added immediately after the object
      # is created, which happens after post_init and before the optional code
      # block that can modify the handler. The _sslsocket_ is not added until
      # tls_begin is called, after the code block.
      #
      # #post_init gives you a chance to manipulate the SSLContext.
      def post_init
      end


      # Called right after the SSL handshake succeeds. This is your "new"
      # #post_init.
      def tls_successful_handshake
        puts "Succesful handshake!"
      end

      # Called right after accept_nonblock fails for some unknown reason. The
      # only parameter contains the OpenSSL::SSL::SSLError object that was
      # thrown.
      #
      # The connection will be closed after this.
      def tls_failed_handshake(e)
        puts "Failed to accept: #{e.inspect}"
      end

      # Override this to do something with the unecrypted data.
      def receive_data(data)
        puts "tls_recv: #{data}"
      end

      # Override this to do something when the socket is finished.
      def unbind
        puts "tls unbind"
      end

    end
  end
end


