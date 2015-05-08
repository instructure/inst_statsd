module CanvasStatsd
  class DefaultTracking

    @ar_counter = CanvasStatsd::Counter.new('ar_counter')
    @sql_tracker = CanvasStatsd::SqlTracker.new(blocked_names: ['SCHEMA'])

    def self.track_default_metrics(options={})
      options = {sql: true, active_record: true}.merge(options)
      track_timing
      track_sql if !!options[:sql]
      track_active_record if !!options[:active_record]
    end

    def self.subscribe type, &block
      ActiveSupport::Notifications.subscribe type, &block
    end

    private

    def self.instrument_active_record_creation
      ::Aroi::Instrumentation.instrument_creation!
    end

    def self.track_timing
      subscribe(/start_processing.action_controller/) {|*args| start_processing(*args)}
      subscribe(/process_action.action_controller/) {|*args| finalize_processing(*args)}
    end

    def self.track_sql
      @tracking_sql = true
      subscribe(/sql.active_record/) {|*args| update_sql_count(*args)}
    end

    def self.track_active_record
      instrument_active_record_creation
      @tracking_active_record = true
      subscribe(/instance.active_record/) {|*args| update_active_record_count(*args)}
    end

    def self.start_processing *args
      @sql_tracker.start
      @ar_counter.start
    end

    def self.update_sql_count name, start, finish, id, payload
      @sql_tracker.track payload.fetch(:name), payload.fetch(:sql)
    end

    def self.update_active_record_count name, start, finish, id, payload
      @ar_counter.track payload.fetch(:name, '')
    end

    def self.finalize_processing *args
      request_stat = CanvasStatsd::RequestStat.new(*args)
      request_stat.ar_count = @ar_counter.finalize_count if @tracking_active_record
      request_stat.sql_read_count = @sql_tracker.num_reads if @tracking_sql
      request_stat.sql_write_count = @sql_tracker.num_writes if @tracking_sql
      request_stat.sql_cache_count = @sql_tracker.num_caches if @tracking_sql
      request_stat.report
    end

  end
end
