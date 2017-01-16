module CanvasStatsd
  class RequestTracking

    def self.track_default_metrics(options={})
      options = {sql: true, active_record: true, cache: true, logger: nil}.merge(options)
      @logger = RequestLogger.new(options[:logger])
      track_timing
      @options = options
      DefaultTracking.track_sql if !!options[:sql]
      DefaultTracking.track_active_record if !!options[:active_record]
      DefaultTracking.track_cache if !!options[:cache]
    end

    private

    def self.track_timing
      ActiveSupport::Notifications.subscribe(/start_processing\.action_controller/, &method(:start_processing))
      ActiveSupport::Notifications.subscribe(/process_action\.action_controller/, &method(:finalize_processing))
    end

    def self.start_processing(*_args)
      @sql_cookies = DefaultTracking.sql_tracker.start if !!@options[:sql]
      @ar_cookie = DefaultTracking.ar_counter.start if !!@options[:active_record]
      @cache_read_cookie = DefaultTracking.cache_read_counter.start if !!@options[:cache]
    end

    def self.finalize_processing *args
      request_stat = CanvasStatsd::RequestStat.new(*args)
      request_stat.ar_count = DefaultTracking.ar_counter.finalize_count(@ar_cookie) if @ar_cookie
      if @sql_cookies
        request_stat.sql_read_count,
            request_stat.sql_write_count,
            request_stat.sql_cache_count = DefaultTracking.sql_tracker.finalize_counts(@sql_cookies)
      end
      request_stat.cache_read_count = DefaultTracking.cache_read_counter.finalize_count(@cache_read_cookie) if @cache_read_cookie
      request_stat.report
      @logger.log(request_stat)
    end
  end
end
