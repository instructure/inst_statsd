# frozen_string_literal: true

module InstStatsd
  class BlockStat
    attr_accessor :stats, :common_key, :short_stat, :tags

    def initialize(common_key, statsd = InstStatsd::Statsd, tags: {}, short_stat: nil)
      self.common_key = common_key
      @tags = tags
      @short_stat = short_stat
      @short_stat ||= common_key
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

      stats.to_h { |key, value| [key, value - (@exclusives[key] || 0.0)] }
    end

    def report
      return unless common_key

      stats.each do |(key, value)|
        @statsd.timing("#{common_key}.#{key}", value, tags: @tags, short_stat: "#{@short_stat}.#{key}")
      end
      exclusive_stats&.each do |(key, value)|
        @statsd.timing("#{common_key}.exclusive.#{key}",
                       value,
                       tags: @tags,
                       short_stat: "#{@short_stat}.exclusive.#{key}")
      end
    end
  end
end
