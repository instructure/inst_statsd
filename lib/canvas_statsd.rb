require 'statsd'

module CanvasStatsd
  VALID_SETTINGS = [:host, :port, :namespace, :append_hostname]

  class ConfigurationError < StandardError; end

  require "canvas_statsd/statsd"
  require "canvas_statsd/block_stat"
  require "canvas_statsd/block_tracking"
  require "canvas_statsd/request_stat"
  require "canvas_statsd/counter"
  require "canvas_statsd/sql_tracker"
  require "canvas_statsd/default_tracking"
  require "canvas_statsd/request_logger"
  require "canvas_statsd/request_tracking"
  require "canvas_statsd/null_logger"

  class << self
    def settings
      @settings || env_settings
    end
  
    def settings=(value)
      @settings = validate_settings(value)
    end
  
    def validate_settings(value)
      return nil if value.nil?
  
      validated = {}
      value.each do |k,v|
        if !VALID_SETTINGS.include?(k.to_sym)
          raise CanvasStatsd::ConfigurationError, "Invalid key: #{k}"
        end
        validated[k.to_sym] = v
      end
  
      env_settings.merge(validated)
    end
  
    def env_settings(env=ENV)
      config = {
        host: env.fetch('CANVAS_STATSD_HOST', nil),
        port: env.fetch('CANVAS_STATSD_PORT', nil),
        namespace: env.fetch('CANVAS_STATSD_NAMESPACE', nil),
        append_hostname: env.fetch('CANVAS_STATSD_APPEND_HOSTNAME', nil),
      }
      config.delete_if {|k,v| v.nil?}
      convert_bool(config, :append_hostname)
      config[:host] ? config : {}
    end
  
    def convert_bool(hash, key)
      value = hash[key]
      return if value.nil?
      unless ['true', 'True', 'false', 'False', true, false].include?(value)
        message = "#{key} must be a boolean, or the string representation of a boolean, got: #{value}"
        raise CanvasStatsd::ConfigurationError, message
      end
      hash[key] = ['true', 'True', true].include?(value)
    end
  
    def track_default_request_metrics options={}
      CanvasStatsd::RequestTracking.track_default_metrics options
    end
    # backcompat
    alias track_default_metrics track_default_request_metrics
  end

end
