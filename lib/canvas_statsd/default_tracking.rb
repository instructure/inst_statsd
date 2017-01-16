require "active_support"

module CanvasStatsd
  class DefaultTracking
    class << self
      attr_reader :ar_counter, :cache_read_counter, :sql_tracker
    end

    @ar_counter = CanvasStatsd::Counter.new('ar_counter')
    @cache_read_counter = CanvasStatsd::Counter.new('cache_read_counter')
    @sql_tracker = CanvasStatsd::SqlTracker.new(blocked_names: ['SCHEMA'])

    protected

    def self.track_sql
      return if @tracking_sql
      @tracking_sql = true
      ActiveSupport::Notifications.subscribe(/sql\.active_record/) {|*args| update_sql_count(*args)}
    end

    def self.track_active_record
      return if @tracking_active_record
      require 'aroi'

      ::Aroi::Instrumentation.instrument_creation!
      @tracking_active_record = true
      ActiveSupport::Notifications.subscribe(/instance\.active_record/) {|*args| update_active_record_count(*args)}
    end

    def self.track_cache
      @tracking_cache = true
      ActiveSupport::Notifications.subscribe(/cache_read\.active_support/) {|*args| update_cache_read_count(*args)}
    end

    def self.update_sql_count(_name, _start, _finish, _id, payload)
      @sql_tracker.track payload.fetch(:name), payload.fetch(:sql)
    end

    def self.update_active_record_count(_name, _start, _finish, _id, payload)
      @ar_counter.track payload.fetch(:name, '')
    end

    def self.update_cache_read_count(_name, _start, _finish, _id, _payload)
      @cache_read_counter.track "read"
    end

  end
end
