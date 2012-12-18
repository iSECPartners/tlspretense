module PacketThief
  module Handlers

    # Instead of forwarding the connection to the original host, forwards it to
    # a configured host instead.
    class ProxyRedirector < TransparentProxy

      def initialize(proxy_host, proxy_port, log=nil)
        super(log)

        @proxy_host = proxy_host
        @proxy_port = proxy_port
      end

      # Instead of using the original destination, use the configured destination.
      def client_connected
        @dest_host = @proxy_host
        @dest_port = @proxy_port
        connect_to_dest
      end

    end

  end
end

