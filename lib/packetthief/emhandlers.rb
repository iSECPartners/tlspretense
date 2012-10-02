require 'eventmachine'

module PacketThief
  module EMHandlers
    autoload :SSLInterceptor,   'packetthief/emhandlers/ssl_interceptor'
    autoload :TransparentProxy, 'packetthief/emhandlers/transparent_proxy'
    autoload :ProxyRedirector,  'packetthief/emhandlers/proxy_redirector'
  end

  # Alias for EMHandlers
  EM = EMHandlers
end

