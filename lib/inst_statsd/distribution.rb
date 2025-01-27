# frozen_string_literal: true

module InstStatsd
  # Mix-in methods for supporting DataDog events
  # See https://docs.datadoghq.com/metrics/types/?tab=distribution#metric-types
  module Distribution
    # Sends a distribution metric to DataDog if the instance and DataDog are configured.
    #
    # Distributions are aggregated globally and are appropriate when a metric sourced from
    # multiple hosts need to be considered in a global statistical distribution.
    #
    # @param metric [String] The name of the metric to send.
    # @param value [Numeric] The value of the metric.
    # @param tags [Hash] Optional tags to associate with the metric. Defaults to an empty hash.
    #
    # @example Record an error occurrence:
    #   InstStatsd::Statsd.distribution('client.request.failed', 1, tags: { status: '500' })
    def distribution(metric, value, tags: {})
      return unless instance && data_dog?

      metric = if append_hostname?
                 "#{metric}.#{hostname}"
               else
                 metric.to_s
               end

      instance.distribution(metric, value, { tags: tags.merge(dog_tags) }.compact)
    end

    # Increments the specified distribution metric by 1.
    #
    # @param metric [String] The name of the metric to increment.
    # @param tags [Hash] Optional tags to associate with the metric.
    # @param short_stat [String, nil] Stat name to use instead of `metric` if backed by DataDog.
    #
    # @example Increment the error count:
    #  InstStatsd::Statsd.distributed_increment('client.request.failed', tags: { status: '500' })
    def distributed_increment(metric, tags: {}, short_stat: nil)
      # Non-Datadog clients don't support distribution metrics, so we use fall back to increment
      return increment(metric, tags: tags, short_stat: short_stat) if instance && !data_dog?

      distribution(short_stat || metric, 1, tags: tags)
    end
  end
end
