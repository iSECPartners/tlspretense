module SSLTest

  # Class to hold onto application-wide values in a single place and to track
  # application state.
  class AppContext

    attr_accessor :config
    attr_accessor :cert_manager
    attr_accessor :logger

    def initialize(config, cert_manager, logger)
      @config = config
      @cert_manager = cert_manager
      @logger = logger
    end
  end
end
