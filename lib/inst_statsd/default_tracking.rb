require "active_support"

module InstStatsd
  class DefaultTracking
    def self.track_sql
      return if @sql_tracker
      @sql_tracker = InstStatsd::SqlTracker.new(blocked_names: ['SCHEMA'])
      ActiveSupport::Notifications.subscribe(/sql\.active_record/) {|*args| update_sql_count(*args)}
    end

    def self.track_active_record
      return if @ar_counter
      require 'aroi'

      ::Aroi::Instrumentation.instrument_creation!
      @ar_counter = InstStatsd::Counter.new('active_record')
      ActiveSupport::Notifications.subscribe(/instance\.active_record/) {|*args| update_active_record_count(*args)}
    end

    def self.track_cache
      return if @cache_read_counter

      @cache_read_counter = InstStatsd::Counter.new('cache.read')
      ActiveSupport::Notifications.subscribe(/cache_read\.active_support/) {|*args| update_cache_read_count(*args)}
    end

    private

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
