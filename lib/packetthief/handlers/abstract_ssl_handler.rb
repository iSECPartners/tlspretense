require 'openssl'

module PacketThief
  module Handlers

    # Parent class for both SSLServer and SSLClient.
    #
    # TODO: get_peer_cert, get_peername, etc.
    class AbstractSSLHandler < ::EM::Connection

      # The OpenSSL::SSL::SSLContext. Modify this in post_init or in the
      # initializing code block to add certificates, etc.
      attr_accessor :ctx

      # The TCPSocket that the SSLSocket will be created from. It is added by
      # #initialize.
      attr_accessor :tcpsocket

      # The SSLSocket. It is not available until #tls_begin creates it, after
      # post_init and the initializing code block.
      attr_accessor :sslsocket

      # (Used by SSLClient only) The hostname that the SNI TLS extension should
      # request. Set it in post_init or in the initializing code block --- it
      # is applied to the SSLSocket during #tls_begin.
      attr_accessor :sni_hostname

      def initialize(tcpsocket)
#        puts "#{self.class} initialize"
        # Set up initial values
        @tcpsocket = tcpsocket
        @ctx = OpenSSL::SSL::SSLContext.new

        @close_after_writing = false
        @state = :new
      end

      # Creates _sslsocket_ from _tcpsocket_ and _ctx_, and initializes the
      # handler's internal state. Called from the class method that creates the
      # object, after post_init and the optional code block.
      #
      # @note (SSLClient only) If @sni_hostname exists on the handler at this
      # point, it will be added to the SSLSocket in order to enable sending a
      # hostname in the SNI TLS extension.
      def tls_begin
#        puts "#{self.class} tls begin"
        @sslsocket = OpenSSL::SSL::SSLSocket.new(@tcpsocket, @ctx)
        @sslsocket.hostname = @sni_hostname if @sni_hostname
        @state = :initialized
      end

      # Calls accept_nonblock/connect_nonblock, read_nonblock, or
      # write_nonblock based on the current state of the connection.
      def notify_readable
#        puts "#{self.class} notify_readable state: #{@state}"
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
#        puts "#{self.class} notify_writable state: #{@state}"
        notify_writable = false # disable it now. if we still need it, we'll renabled it.
        case @state
        when :initialized
          attempt_connection
        when :read_needs_to_write
          attempt_read
        when :write_needs_to_write
          attempt_write
        end

        # if we waiting to close and are not longer waiting to write, we can flush and close the connection.
        if @close_after_writing and not notify_writable?
          @sslsock.flush
          close_connection
        end
      end

      private
      def attempt_connection
        begin
          # Client usess connect_nonblock, while server uses accept_nonblock.
          connection_action
          @state = :ready_to_read
          tls_successful_handshake
          attempt_write if write_buffer.length > 0
        rescue IO::WaitReadable
          # accept_nonblock needs to wait until it can read again.
          notify_readable = true
        rescue IO::WaitWritable
          # accept_nonblock needs to wait until it can write again.
          notify_writable = true
        rescue OpenSSL::SSL::SSLError => e
          # ssl handshake failed. Likely due to client rejecting our certificate!
          tls_failed_handshake(e)
          close_connection
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
          close_connection
        rescue IO::WaitReadable
          # we had no data to read.
          notify_readable = true
        rescue IO::WaitWritable
          # we ran out of buffer to send (yes, SSLSocket#read_nonblock can
          # trigger this)
          @state = :read_needs_to_write
          notify_writable = true
        rescue OpenSSL::SSL::SSLError => e
          puts "SSLError: #{self.inspect} : #{e.inspect}"
          close_connection
        else
          @state = :ready_to_read
        end
      end

      public
      def write_buffer
        @write_buffer ||= ""
      end

      public
      def write_buffer=(rhs)
        @write_buffer = rhs
      end

      private
      def attempt_write(data=nil)
#        puts "#{self.class} attempt_write"
        write_buffer << data if data
        # do not attempt to write until we are ready!
        return if @state == :initialized or @state == :new
        begin
          count_written = @sslsocket.write_nonblock write_buffer
        rescue IO::WaitWritable
          notify_writable = true
        rescue IO::WaitReadable
          @state = :write_needs_to_read
        rescue OpenSSL::SSL::SSLError => e
          puts "SSLError: #{self.inspect} : #{e.inspect}"
          close_connection
        else
          # shrink the buf
          #
          # byteslice was added in ruby 1.9.x. in ruby 1.8.7, bytesize is
          # aliased to length, implying that a character coresponds to a
          # byte.
          @write_buffer = if write_buffer.respond_to?(:byteslice)
                            write_buffer.byteslice(count_written..-1)
                          else
                            write_buffer.slice(count_written..-1)
                          end
          # if we didn't write everything, wait for writable.
          notify_writable = true if write_buffer.bytesize > 0
        end
      end

      ####

      public

      # Call this to send data to the other end of the connection.
      def send_data(data)
#        puts "#{self.class} send_data"
        attempt_write(data)
      end

      def close_connection
        detach
        @sslsocket.close if @sslsocket
        @tcpsocket.close
#        unbind
      end

      def close_connection_after_writing
        @close_after_writing = true
        # if we aren't waiting to write, then we can flush and close.
        if not notify_writable?
          @sslsocket.flush
          close_connection
        end

      end


      # Note that post_init dos not have access to the _sslsocket_. The
      # _sslsocket_ is not added until tls_begin is called, after the code
      # block.
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
        puts "#{self.inspect} Failed to accept: #{e.inspect}"
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


