module CanvasStatsd
  class RequestLogger

    VALUES_MAP = {
        total: :ms,
        view: :view_runtime,
        db: :db_runtime,
        sql_read: :sql_read_count,
        sql_write: :sql_write_count,
        sql_cache: :sql_cache_count,
        active_record: :ar_count,
        cache_read: :cache_read_count,
      }.freeze


    def initialize(logger)
      @logger = logger || CanvasStatsd::NullLogger.new
    end

    def log(request_stat, header=nil)
      @logger.info(build_log_message(request_stat, header))
    end

    def build_log_message(request_stat, header=nil)
      header ||= "STATSD"
      message = "[#{header}]"
      VALUES_MAP.each do |k,v|
        value = request_stat.respond_to?(v) ? request_stat.send(v) : nil
        message += " (#{k}: #{"%.2f" % value})" if value
      end
      message
    end

  end
end
