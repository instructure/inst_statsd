# frozen_string_literal: true

require "benchmark"

module InstStatsd
  class BlockTracking
    class << self
      attr_accessor :logger

      %i[mask negative_mask].each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method}                              # def mask
            InstStatsd.settings[:#{method}]          #  InstStatsd.settings[:mask]
          end                                        # end
                                                     #
          def #{method}=(value)                      # def mask=(value)
            InstStatsd.settings[:#{method}] = value  #  InstStatsd.settings[:mask] = value
          end                                        # end
        RUBY
      end

      def track(key, category: nil, statsd: InstStatsd::Statsd, only: nil, tags: {}, short_stat: nil)
        return yield if mask && mask !~ key
        return yield if negative_mask && negative_mask =~ key

        cookies = if only
                    Array(only).map { |name| [name, Counter.counters[name].start] }
                  else
                    Counter.counters.map { |(name, counter)| [name, counter.start] }
                  end
        block_stat = InstStatsd::BlockStat.new(key, statsd, tags: tags, short_stat: short_stat)
        stack(category).push(block_stat) if category

        result = nil
        elapsed = Benchmark.realtime do
          result = yield
        end
        # to be consistent with ActionPack, measure in milliseconds
        elapsed *= 1000

        block_stat.stats = cookies.to_h { |(name, cookie)| [name, Counter.counters[name].finalize_count(cookie)] }
        block_stat.stats["total"] = elapsed
        # we need to make sure to report exclusive timings, even if nobody called us re-entrantly
        block_stat.subtract_exclusives({}) if category
        block_stat.report
        logger&.log(block_stat, "STATSD #{key}")
        # -1 is ourselves; we want to subtract from the block above us
        stack(category)[-2].subtract_exclusives(block_stat.stats) if category && stack(category)[-2]

        result
      ensure
        stack(category).pop if category && stack(category).last == block_stat
      end

      private

      def stack(category)
        Thread.current[:stats_block_stack] ||= {}
        Thread.current[:stats_block_stack][category] ||= []
      end
    end
  end
end
