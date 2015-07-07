require 'statsd'
require "aroi" if defined?(ActiveRecord)

module CanvasStatsd

  @settings = {}

  class ConfigurationError < StandardError; end

  require "canvas_statsd/statsd"
  require "canvas_statsd/request_stat"
  require "canvas_statsd/counter"
  require "canvas_statsd/sql_tracker"
  require "canvas_statsd/default_tracking"
  require "canvas_statsd/request_logger"
  require "canvas_statsd/null_logger"

  def self.settings
    env_settings.merge(@settings)
  end

  def self.settings=(value)
    @settings = value
  end

  def self.env_settings(env=ENV)
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

  def self.convert_bool(hash, key)
    value = hash[key]
    return if value.nil?
    unless ['true', 'True', 'false', 'False', true, false].include?(value)
      message = "#{key} must be a boolean, or the string representation of a boolean, got: #{value}"
      raise CanvasStatsd::ConfigurationError, message
    end
    hash[key] = ['true', 'True', true].include?(value)
  end

  def self.track_default_metrics options={}
    CanvasStatsd::DefaultTracking.track_default_metrics options
  end

end
