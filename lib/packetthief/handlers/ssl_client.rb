module PacketThief
  module Handlers

    # Basic SSL/TLS Client built on Ruby's OpenSSL objects instead of on
    # EventMachine's start_tls. This allows you to manipulate the SSLContext
    # and other details of the connection that EM normally doesn't let you
    # touch.
    #
    # Subclass it and override any of the methods in the following example to
    # use the the functionality.
    #
    # You can #send_data to send encrypted data to the other side, and
    # #receive_data will be called when there is data for the handler.
    #
    #   EM.run {
    #     SSLClient.connect "www.isecpartners.com", 443 do |p|
    #
    #       # Note: this code block is actually too late to set up a new
    #       # #post_init since it runs just after post_init. You can use
    #       # #post_init on a subclass though.
    #       def p.post_init
    #         # modify p.ctx to configure your certificates, key, etc.
    #       end
    #
    #       # The following makes more sense for the initialization block.
    #       h.ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    #
    #       def p.tls_successful_handshake
    #         # the handshake succeeded
    #       end
    #
    #       def p.tls_failed_handshake(e)
    #         # the ssl handshake failed, probably due to the client rejecting
    #         # your certificate. =)
    #       end
    #
    #       def p.unbind
    #         # unbind handler, called regardless of handshake success
    #       end
    #
    #       def p.receive_data(data)
    #         # do something with the unencrypted stream
    #         p.send_data("some message") # data to be encrypted then sent to the client
    #       end
    #
    #     end
    #   }
    #
    # Note: During #initialize and #post_init, this class
    # does not have access to its socket yet. Instead, use #tls_pre_start or
    # the code block you pass to .start to initialize the SSLContext, and use
    # #tls_successful_handshake to do anything once the SSL handshake has
    # completed.
    class SSLClient < AbstractSSLHandler

      def self.connect(host, port, *args, &block)
        ssl_class = self

        sock = TCPSocket.new host, port

        ::EM.watch sock, ssl_class, sock, *args do |h|
          h.notify_readable = true
#          h.notify_writable = true
          block.call(h) if block
          h.tls_begin
        end
      end

      ####

      private
      # SSLClient uses connect_nonblock instead of accept_nonblock.
      def connection_action
        @sslsocket.connect_nonblock
      end

      ####

      public
      def tls_begin
        super
        attempt_connection
      end

    end
  end
end
