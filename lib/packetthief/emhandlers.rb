require 'eventmachine'

module PacketThief
  module EMHandlers
    autoload :AbstractSSLHandler, 'packetthief/emhandlers/abstract_ssl_handler'
    autoload :SSLClient,   'packetthief/emhandlers/ssl_client'
    autoload :SSLServer,   'packetthief/emhandlers/ssl_server'
    autoload :TransparentProxy, 'packetthief/emhandlers/transparent_proxy'
    autoload :ProxyRedirector,  'packetthief/emhandlers/proxy_redirector'
  end

  # Alias for EMHandlers
  EM = EMHandlers
end

