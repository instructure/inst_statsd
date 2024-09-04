# frozen_string_literal: true

module InstStatsd
  # Mix-in methods for supporting DataDog events
  # See https://docs.datadoghq.com/service_management/events/
  module Event
    DEPLOY_EVENT = "deploy"
    FEATURE_EVENT = "feature"
    PROVISION_EVENT = "provision"
    REFRESH_EVENT = "refresh"

    SUPPORTED_TYPES = [
      DEPLOY_EVENT,
      FEATURE_EVENT,
      PROVISION_EVENT,
      REFRESH_EVENT
    ].freeze

    def instance; end
    def data_dog?; end
    def dog_tags; end

    # A dynamic method that uses the class constants to create a specific event type
    #
    # @param [String] title Event title
    # @param [String] description Event description. Supports newlines (+\n+)
    # @param [Hash] :tags tags to be added to event. Note that the
    #   environment, service, and other data are automatically
    #   added as tags for you without specifying them here.
    # @param [String, nil] :date_happened (nil) Assign a timestamp
    #
    # @example Report a flag flip event:
    #   InstStatsd::Statsd.feature_event(
    #     "Feature Flag Change",
    #     "Feature flag <flag_name> was flipped to <flag_state>",
    #     tags: {foo: 'bar'}
    #   )

    SUPPORTED_TYPES.each do |event_name|
      define_method("#{event_name}_event") do |*args, **kwargs|
        event(
          *args,
          type: event_name,
          alert_type: :success,
          priority: :normal,
          **kwargs
        )
      end
    end

    # This end point allows you to post events to the DataDog event stream.
    #
    # @param [String] title Event title
    # @param [String] description Event description. Supports newlines (+\n+)
    # @param [String, nil] :type. It is recommended to use the constants
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
    def event(title, description, type: nil, tags: {}, alert_type: nil, priority: nil, date_happened: nil)
      return unless instance && data_dog?

      instance.event(
        title,
        description,
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
      custom_tags[:type] = type
      custom_tags.compact
    end
  end
end
