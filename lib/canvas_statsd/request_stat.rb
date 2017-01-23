module CanvasStatsd
  class RequestStat < BlockStat
    def initialize(name, start, finish, id, payload, statsd=CanvasStatsd::Statsd)
      super(nil, statsd)
      @name = name
      @start = start
      @finish = finish
      @id = id
      @payload = payload
    end

    def common_key
      common_key = super
      return common_key if common_key
      self.common_key = "request.#{controller}.#{action}" if controller && action
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

    def total
      if (!@finish || !@start)
        return 0
      end
      (@finish - @start) * 1000
    end

  end
end
