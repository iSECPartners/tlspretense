require 'eventmachine'

module PacketThief
  module Handlers
    autoload :AbstractSSLHandler, 'packetthief/handlers/abstract_ssl_handler'
    autoload :SSLClient,   'packetthief/handlers/ssl_client'
    autoload :SSLServer,   'packetthief/handlers/ssl_server'
    autoload :SSLSmartProxy,        'packetthief/handlers/ssl_smart_proxy'
    autoload :SSLTransparentProxy,  'packetthief/handlers/ssl_transparent_proxy'
    autoload :TransparentProxy, 'packetthief/handlers/transparent_proxy'
    autoload :ProxyRedirector,  'packetthief/handlers/proxy_redirector'
  end
end

