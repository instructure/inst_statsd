# frozen_string_literal: true

module InstStatsd
  class SqlTracker
    attr_reader :blocked_names, :read_counts, :write_counts, :cache_counts

    def initialize(opts = nil)
      opts ||= {}
      @blocked_names = opts.fetch(:blocked_names, [])
      @read_counts = opts.fetch(:read_counter, InstStatsd::Counter.new("sql.read"))
      @write_counts = opts.fetch(:write_counter, InstStatsd::Counter.new("sql.write"))
      @cache_counts = opts.fetch(:cache_counter, InstStatsd::Counter.new("sql.cache"))
    end

    def start
      [read_counts, write_counts, cache_counts].map(&:start)
    end

    def track(name, sql)
      return unless sql && accepted_name?(name)

      if name.include?("CACHE")
        cache_counts.track name
      elsif truncate(sql).include?("SELECT") || name.include?("LOAD")
        read_counts.track(sql)
      else
        write_counts.track(sql)
      end
    end

    def finalize_counts(cookies)
      [
        read_counts.finalize_count(cookies[0]),
        write_counts.finalize_count(cookies[1]),
        cache_counts.finalize_count(cookies[2])
      ]
    end

    private

    def accepted_name?(name)
      !!(name && !blocked_names.include?(name))
    end

    def truncate(sql, length = 15)
      sql ||= ""
      sql.strip[0..length]
    end
  end
end
