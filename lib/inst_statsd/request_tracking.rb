# frozen_string_literal: true

module InstStatsd
  class RequestTracking

    def self.enable(logger: nil)
      @logger = RequestLogger.new(logger)
      track_timing
    end

    private

    def self.track_timing
      ActiveSupport::Notifications.subscribe(/start_processing\.action_controller/, &method(:start_processing))
      ActiveSupport::Notifications.subscribe(/process_action\.action_controller/, &method(:finalize_processing))
    end

    def self.start_processing(*_args)
      @cookies = Counter.counters.map { |(name, counter)| [name, counter.start] }
    end

    def self.finalize_processing *args
      request_stat = InstStatsd::RequestStat.new(*args)
      request_stat.stats = @cookies.map { |(name, cookie)| [name, Counter.counters[name].finalize_count(cookie)] }.to_h
      request_stat.report
      @logger.log(request_stat)
    end
  end
end
