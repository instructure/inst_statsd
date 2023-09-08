# frozen_string_literal: true

# Proxy class to communicate messages to statsd
# Available statsd messages are described in:
#   https://github.com/etsy/statsd/blob/master/README.md
#   https://github.com/reinh/statsd/blob/master/lib/statsd.rb
#
# So for instance:
#   ms = Benchmark.ms { ..code.. }
#   InstStatsd::Statsd.timing("my_stat", ms)
#
# Configured in config/statsd.yml, see config/statsd.yml.example
# At least a host needs to be defined for the environment, all other config is
# optional
#
# If a namespace is defined in statsd.yml, it'll be prepended to the stat name.
# The hostname of the server will be appended to the stat name, unless
# `append_hostname: false` is specified in the config.
# So if the namespace is "canvas" and the hostname is "app01", the final stat
# name of "my_stat" would be "stats.canvas.my_stat.app01" (assuming the default
# statsd/graphite configuration)
#
# If dog_tags is set in statsd.yml, it'll use the tags param and will use
# Data Dog instead of Statsd
#
# If statsd isn't configured and enabled, then calls to InstStatsd::Statsd.*
# will do nothing and return nil

module InstStatsd
  module Statsd
    extend InstStatsd::Event

    # replace "." in key names with another character to avoid creating spurious sub-folders in graphite
    def self.escape(str, replacement = "_")
      str.respond_to?(:gsub) ? str.gsub(".", replacement) : str
    end

    def self.hostname
      @hostname ||= Socket.gethostname.split(".").first
    end

    def self.dog_tags
      @dog_tags ||= {}
    end

    %w[increment decrement count gauge timing].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{method}(stat, *args, tags: {}, short_stat: nil)      # def self.increment(stat, *args, tags: {}, short_stat: nil)
          if self.instance                                              #   if self.instance
            if Array === stat                                           #     if Array === stat
              stat.each do |st|                                         #       stat.each do |st|
                self.#{method}(st, *args, tags: tags, short_stat: nil)  #        self.increment(st, *args, tags: tags, short_stat: nil)
              end                                                       #       end
              return                                                    #       return
            end                                                         #     end
                                                                        #
            if self.append_hostname?                                    #     if self.append_hostname?
              stat_name = "\#{stat}.\#{hostname}"                       #       stat_name = "\#{stat}.\#{hostname}"
            else                                                        #     else
              stat_name = stat.to_s                                     #       stat_name = stat.to_s
            end                                                         #     end
                                                                        #
            if data_dog?                                                #     if data_dog?
              tags = tags ? tags.dup : {}                               #       tags ||= {}
              tags.merge!(dog_tags) if tags.is_a? Hash                  #       tags.merge!(dog_tags) if tags.is_a? Hash
              tags = convert_tags(tags)                                 #       tags = convert_tags(tags)
              tags << 'host:' unless self.append_hostname?              #       tags << 'host:' unless self.append_hostname?
              short_stat ||= stat_name                                  #       short_stat ||= stat_name
              opts = { tags: tags }                                     #       opts = { tags: tags }
              opts[:sample_rate] = args.pop if args.length == 2         #       opts[:sample_rate] = args.pop if args.length == 2
              args << opts                                              #       args << opts
              self.instance.#{method}(short_stat, *args)                #       self.instance.increment(short_stat, *args)
            else                                                        #     else
              self.instance.#{method}(stat_name, *args)                 #       self.instance.increment(stat_name, *args)
            end                                                         #     end
          else                                                          #   else
            nil                                                         #     nil
          end                                                           #   end
        end                                                             # end
      RUBY
    end

    def self.convert_tags(tags)
      new_tags = []
      return tags unless tags.is_a? Hash

      tags.each do |tag, v|
        new_tags << "#{tag}:#{v}"
      end

      new_tags
    end

    def self.time(stat, sample_rate = 1, tags: {}, short_stat: nil)
      start = Time.now
      result = yield
      timing(stat, ((Time.now - start) * 1000).round, sample_rate, tags: tags, short_stat: short_stat)
      result
    end

    def self.batch
      return yield unless (old_instance = instance)

      old_instance.batch do |batch|
        Thread.current[:inst_statsd] = batch
        yield
      end
    ensure
      Thread.current[:inst_statsd] = old_instance
    end

    def self.instance
      thread_statsd = Thread.current[:inst_statsd]
      return thread_statsd if thread_statsd

      unless defined?(@statsd)
        statsd_settings = InstStatsd.settings
        if statsd_settings.key?(:dog_tags)
          @data_dog = true
          host = statsd_settings[:host] || "localhost"
          port = statsd_settings[:port] || 8125
          socket_path = statsd_settings[:socket_path]
          require "datadog/statsd"
          @statsd = if socket_path
                      Datadog::Statsd.new(socket_path: socket_path, namespace: statsd_settings[:namespace])
                    else
                      Datadog::Statsd.new(host, port, namespace: statsd_settings[:namespace])
                    end
          dog_tags.replace(statsd_settings[:dog_tags] || {})
          @append_hostname = statsd_settings[:append_hostname]
        elsif statsd_settings && statsd_settings[:host]
          @statsd = ::Statsd.new(statsd_settings[:host])
          @statsd.port = statsd_settings[:port] if statsd_settings[:port]
          @statsd.namespace = statsd_settings[:namespace] if statsd_settings[:namespace]
          @statsd.batch_size = statsd_settings[:batch_size] if statsd_settings.key?(:batch_size)
          @statsd.batch_byte_size = statsd_settings[:batch_byte_size] if statsd_settings.key?(:batch_byte_size)
          @append_hostname = statsd_settings[:append_hostname]
        else
          @statsd = nil
        end
      end
      @statsd
    end

    def self.append_hostname?
      @append_hostname
    end

    def self.data_dog?
      @data_dog
    end

    def self.reset_instance
      remove_instance_variable(:@statsd) if defined?(@statsd)
      Thread.current[:inst_statsd] = nil
    end
  end
end
