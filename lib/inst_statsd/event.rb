# frozen_string_literal: true

module InstStatsd
  # Mix-in methods for supporting DataDog events
  # See https://docs.datadoghq.com/service_management/events/
  module Event
    SUPPORTED_TYPES = %i[
      deploy
      feature_disabled
      feature_enabled
      provision
      refresh
    ].freeze

    def instance; end
    def data_dog?; end
    def dog_tags; end

    # This end point allows you to post events to the DatDog event stream.
    #
    # @param [String] title Event title
    # @param [String] text Event text. Supports newlines (+\n+)
    # @param [String, nil] :type Can be "deploy", "feature_disabled",
    #   "feature_enabled", "provision", or "refresh"
    # @param [Hash] :tags tags to be added to event. Note that the
    #   environment, service, and other data are automatically
    #   added as tags for you without specifying them here.
    # @param [Integer, String, nil] :date_happened (nil) Assign a timestamp
    #   to the event. Default is now when none
    # @param [String, nil] :priority ('normal') Can be "normal" or "low"
    # @param [String, nil] :alert_type ('info') Can be "error", "warning", "info" or "success".
    #
    # @example Report an event:
    #   InstStatsd::Statsd.event(
    #       "Quiz API Deploy",
    #       "<release> was deployed to Quiz API",
    #       tags: {foo: 'bar'},
    #       type: 'deploy',
    #       alert_type: :success
    #   )
    def event(title, text, type: nil, tags: {}, alert_type: nil, priority: nil, date_happened: nil)
      return unless instance && data_dog?

      instance.event(
        title,
        text,
        **{
          alert_type: alert_type,
          priority: priority,
          date_happened: date_happened,
          tags: tags_from_opts(tags, type, dog_tags)
        }.compact
      )
    end

    private

    def tags_from_opts(tags, type, dd_tags)
      custom_tags = tags.merge(dd_tags)
      custom_tags[:type] = type.to_sym if SUPPORTED_TYPES.include? type&.to_sym
      custom_tags.compact
    end
  end
end
