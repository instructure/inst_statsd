module CanvasStatsd
  class BlockStat

    attr_accessor :stats
    attr_accessor :common_key

    def initialize(common_key, statsd=CanvasStatsd::Statsd)
      self.common_key = common_key
      @statsd = statsd
      @stats = {}
    end

    def subtract_exclusives(stats)
      @exclusives ||= {}
      stats.each do |(key, value)|
        @exclusives[key] ||= 0.0
        @exclusives[key] += value
      end
    end

    def exclusive_stats
      return nil unless @exclusives
      stats.map { |key, value| [key, value - (@exclusives[key] || 0.0)] }.to_h
    end

    def report
      if common_key
        stats.each do |(key, value)|
          @statsd.timing("#{common_key}.#{key}", value)
        end
        exclusive_stats&.each do |(key, value)|
          @statsd.timing("#{common_key}.exclusive.#{key}", value)
        end
      end
    end
  end
end
