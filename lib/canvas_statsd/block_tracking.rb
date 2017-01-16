require 'benchmark'

module CanvasStatsd
  class BlockTracking
    class << self
      attr_accessor :logger

      def track(key, sql: true, active_record: true, cache: true, statsd: CanvasStatsd::Statsd)
        sql_cookies = DefaultTracking.sql_tracker.start if sql
        ar_cookie = DefaultTracking.ar_counter.start if active_record
        cache_read_cookie = DefaultTracking.cache_read_counter.start if cache

        result = nil
        elapsed = Benchmark.realtime do
          result = yield
        end
        # to be consistent with ActionPack, measure in milliseconds
        elapsed *= 1000

        block_stat = CanvasStatsd::BlockStat.new(key, statsd)
        block_stat.total = elapsed
        block_stat.ar_count = DefaultTracking.ar_counter.finalize_count(ar_cookie) if active_record
        block_stat.sql_read_count,
          block_stat.sql_write_count,
          block_stat.sql_cache_count = DefaultTracking.sql_tracker.finalize_counts(sql_cookies) if sql
        block_stat.cache_read_count = DefaultTracking.cache_read_counter.finalize_count(cache_read_cookie) if cache
        block_stat.report
        logger.log(block_stat, "STATSD #{key}") if logger

        result
      end
    end

  end
end
