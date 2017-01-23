module CanvasStatsd
  class Counter
    class << self
      def counters
        @counters ||= {}
      end

      def register(counter)
        counters[counter.key] = counter
      end
    end

    attr_reader :key
    attr_reader :blocked_names

    def initialize(key, blocked_names=[])
      @blocked_names = blocked_names
      @key = key
      @tls_key = "statsd.#{key}"
      self.class.register(self)
    end

    def start
      Thread.current[@tls_key] ||= 0
    end

    def track(name)
      Thread.current[@tls_key] += 1 if Thread.current[@tls_key] && accepted_name?(name)
    end

    def finalize_count(cookie)
      Thread.current[@tls_key] - cookie
    end

    def count
      Thread.current[@tls_key]
    end

    def accepted_name?(name)
      !blocked_names.include?(name)
    end

  end
end
