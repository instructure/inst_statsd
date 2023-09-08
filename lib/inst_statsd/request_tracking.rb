# frozen_string_literal: true

module InstStatsd
  class RequestTracking
    class << self
      def enable(logger: nil)
        @logger = RequestLogger.new(logger)
        track_timing
      end

      private

      def track_timing
        ActiveSupport::Notifications.subscribe(/start_processing\.action_controller/, &method(:start_processing))
        ActiveSupport::Notifications.subscribe(/process_action\.action_controller/, &method(:finalize_processing))
      end

      def start_processing(*_args)
        @cookies = Counter.counters.map { |(name, counter)| [name, counter.start] }
      end

      def finalize_processing *args
        request_stat = InstStatsd::RequestStat.new(*args)
        request_stat.stats = @cookies.to_h { |(name, cookie)| [name, Counter.counters[name].finalize_count(cookie)] }
        request_stat.report
        @logger.log(request_stat)
      end
    end
  end
end
