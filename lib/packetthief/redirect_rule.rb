
module PacketThief
  class RedirectRule
    attr_accessor :handler
    attr_accessor :rulespec
    attr_accessor :redirectspec

    def initialize(handler)
      @handler = handler
    end

    # specify an original destination
    def where(args)
      rule = clone
      rule.rulespec = args
      rule
    end

    def redirect(args)
      rule = clone
      rule.redirectspec = args
      rule
    end

    def run
      @handler.run(self)
    end
  end
end
