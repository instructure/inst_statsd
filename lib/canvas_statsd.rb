require 'statsd'

module CanvasStatsd
  require "canvas_statsd/statsd"
  require "canvas_statsd/request_stat"
  require "canvas_statsd/counter"

  def self.settings
    @settings || env_settings
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
    config[:append_hostname] = false if config[:append_hostname] == 'false';
    config[:append_hostname] = true if config[:append_hostname] == 'true';
    config[:host] ? config : {}
  end

end
