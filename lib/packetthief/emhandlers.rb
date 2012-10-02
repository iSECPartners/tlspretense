require 'eventmachine'

module PacketThief
  module EMHandlers
    autoload :SSLServer,   'packetthief/emhandlers/ssl_server'
    autoload :TransparentProxy, 'packetthief/emhandlers/transparent_proxy'
    autoload :ProxyRedirector,  'packetthief/emhandlers/proxy_redirector'
  end

  # Alias for EMHandlers
  EM = EMHandlers
end

