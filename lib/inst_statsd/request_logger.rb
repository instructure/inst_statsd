module InstStatsd
  class RequestLogger

    def initialize(logger)
      @logger = logger || InstStatsd::NullLogger.new
    end

    def log(request_stat, header=nil)
      @logger.info(build_log_message(request_stat, header))
    end

    def build_log_message(request_stat, header=nil)
      header ||= "STATSD"
      message = "[#{header}]"
      request_stat.stats.each do |(name, value)|
        message += " (#{name.to_s.gsub('.', '_')}: #{"%.2f" % value})"
      end
      request_stat.exclusive_stats&.each do |(name, value)|
        message += " (exclusive_#{name.to_s.gsub('.', '_')}: #{"%.2f" % value})"
      end
      message
    end

  end
end
