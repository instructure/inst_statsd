# frozen_string_literal: true

require "statsd"

module InstStatsd
  VALID_SETTINGS = %i[host
                      port
                      namespace
                      append_hostname
                      mask
                      negative_mask
                      batch_size
                      batch_byte_size
                      dog_tags
                      socket_path].freeze

  class ConfigurationError < StandardError; end

  require "inst_statsd/distribution"
  require "inst_statsd/event"
  require "inst_statsd/statsd"
  require "inst_statsd/block_stat"
  require "inst_statsd/block_tracking"
  require "inst_statsd/request_stat"
  require "inst_statsd/counter"
  require "inst_statsd/sql_tracker"
  require "inst_statsd/default_tracking"
  require "inst_statsd/request_logger"
  require "inst_statsd/request_tracking"
  require "inst_statsd/null_logger"

  class << self
    def settings
      @settings ||= env_settings
    end

    def settings=(value)
      @settings = validate_settings(value)
    end

    def validate_settings(value)
      return nil if value.nil?

      validated = {}
      regexp_methods = %i[mask negative_mask]
      value.each do |k, v|
        raise InstStatsd::ConfigurationError, "Invalid key: #{k}" unless VALID_SETTINGS.include?(k.to_sym)

        v = Regexp.new(v) if regexp_methods.include?(k.to_sym) && v.is_a?(String)
        validated[k.to_sym] = v
      end

      env_settings.merge(validated)
    end

    def env_settings(env = ENV)
      dog_tags = JSON.parse(env["INST_DOG_TAGS"]).to_h if env["INST_DOG_TAGS"]
      config = {
        host: env.fetch("INST_STATSD_HOST", nil),
        port: env.fetch("INST_STATSD_PORT", nil),
        namespace: env.fetch("INST_STATSD_NAMESPACE", nil),
        append_hostname: env.fetch("INST_STATSD_APPEND_HOSTNAME", nil),
        dog_tags: dog_tags
      }
      config.compact!
      convert_bool(config, :append_hostname)
      if config[:host] || config[:dog_tags]
        config
      else
        {}
      end
    end

    def convert_bool(hash, key)
      value = hash[key]
      return if value.nil?

      unless ["true", "True", "false", "False", true, false].include?(value)
        message = "#{key} must be a boolean, or the string representation of a boolean, got: #{value}"
        raise InstStatsd::ConfigurationError, message
      end
      hash[key] = ["true", "True", true].include?(value)
    end
  end
end
