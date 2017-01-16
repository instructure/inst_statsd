module CanvasStatsd
  class BlockStat

    attr_accessor :total
    attr_accessor :sql_read_count
    attr_accessor :sql_write_count
    attr_accessor :sql_cache_count
    attr_accessor :ar_count
    attr_accessor :cache_read_count
    attr_accessor :common_key

    def initialize(common_key, statsd=CanvasStatsd::Statsd)
      self.common_key = common_key
      @statsd = statsd
    end

    def report
      if common_key
        @statsd.timing("#{common_key}.total", total) if total
        @statsd.timing("#{common_key}.sql.read", sql_read_count) if sql_read_count
        @statsd.timing("#{common_key}.sql.write", sql_write_count) if sql_write_count
        @statsd.timing("#{common_key}.sql.cache", sql_cache_count) if sql_cache_count
        @statsd.timing("#{common_key}.active_record", ar_count) if ar_count
        @statsd.timing("#{common_key}.cache.read", cache_read_count) if cache_read_count
      end
    end
  end
end
