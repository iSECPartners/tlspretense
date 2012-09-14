require 'eventmachine'

module PacketThief
  module EMHandlers
    autoload :TransparentProxy, 'packetthief/emhandlers/transparent_proxy'
  end

  # Alias for EMHandlers
  EM = EMHandlers
end

