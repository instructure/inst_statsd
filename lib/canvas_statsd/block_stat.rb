module CanvasStatsd
  class BlockStat

    attr_accessor :stats
    attr_accessor :common_key

    def initialize(common_key, statsd=CanvasStatsd::Statsd)
      self.common_key = common_key
      @statsd = statsd
      @stats = {}
    end

    def report
      if common_key
        stats.each do |(key, value)|
          @statsd.timing("#{common_key}.#{key}", value)
        end
      end
    end
  end
end
