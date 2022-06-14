# frozen_string_literal: true

module InstStatsd
  class RequestStat < BlockStat
    def initialize(name, start, finish, id, payload, statsd=InstStatsd::Statsd)
      super(nil, statsd)
      @name = name
      @start = start
      @finish = finish
      @id = id
      @payload = payload
      @statsd  = statsd
    end

    def common_key
      common_key = super
      return common_key if common_key
      if @statsd.data_dog?
        self.common_key = "request"
        self.short_stat = "request"
        self.tags[:controller] = controller if controller
        self.tags[:action] = action if action
        self.tags[:status] = status if status
      else
        self.common_key = "request.#{controller}.#{action}" if controller && action
      end
    end

    def report
      stats['total'] = total
      stats['view'] = view_runtime if view_runtime
      stats['db'] = db_runtime if db_runtime
      super
    end

    def db_runtime
      @payload.fetch(:db_runtime, nil)
    end

    def view_runtime
      @payload.fetch(:view_runtime, nil)
    end

    def controller
      @payload.fetch(:params, {})['controller']
    end

    def action
      @payload.fetch(:params, {})['action']
    end

    def status
      status = @payload.fetch(:status, 0)
      # Only return status group to reduce the number of indexed custom metrics (and cost) of datadog
      return '1XX' if status >= 100 and status < 200
      return '2XX' if status >= 200 and status < 300
      return '3XX' if status >= 300 and status < 400
      return '4XX' if status >= 400 and status < 500
      return '5XX' if status >= 500 and status < 600
      nil
    end

    def total
      if (!@finish || !@start)
        return 0
      end
      (@finish - @start) * 1000
    end

  end
end
