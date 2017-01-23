require 'benchmark'

module CanvasStatsd
  class BlockTracking
    class << self
      attr_accessor :logger

      def track(key, statsd: CanvasStatsd::Statsd)
        cookies = Counter.counters.map { |(name, counter)| [name, counter.start] }

        result = nil
        elapsed = Benchmark.realtime do
          result = yield
        end
        # to be consistent with ActionPack, measure in milliseconds
        elapsed *= 1000

        block_stat = CanvasStatsd::BlockStat.new(key, statsd)
        block_stat.stats = cookies.map { |(name, cookie)| [name, Counter.counters[name].finalize_count(cookie)] }.to_h
        block_stat.stats['total'] = elapsed
        block_stat.report
        logger.log(block_stat, "STATSD #{key}") if logger

        result
      end
    end

  end
end
