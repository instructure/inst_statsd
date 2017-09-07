# InstStatsd

configurable statsd client proxy

## Configuration

Set a few enviroment variables:

```bash
export INST_STATSD_HOST=statsd.example.org
export INST_STATSD_PORT=1234
export INST_STATSD_NAMESPACE=my_app.prod
export INST_STATSD_APPEND_HOSTNAME=false
```

Or pass a hash to `InstStatsd.settings`

```ruby
settings = {
  host: 'statsd.example.org'
  port: 1234
  namespace: 'my_app.prod'
  append_hostname: false
}

InstStatsd.settings = settings
```

Values passed to `InstStatsd.settings` will be merged into and take precedence over any existing ENV vars

## Configuration Options

Only the `host` (or `INST_STATSD_HOST` ENV var) is required, all other config
is optional

##### `host`

Location of the statsd box you want to send stats to.

##### `port`

port of the statsd box you want to send stats to.

##### `namespace`

If a namespace is defined, it'll be prepended to the stat name. So the following:

```ruby
settings = {
  host: 'statsd.example.org'
  namespace: 'my_app.prod'
}

InstStatsd.settings = settings

InstStatsd::Statsd.timing('some.stat', 300)
```

would use `my_app.prod.some.stat` as it's stat name.


##### `append_hostname`

The hostname of the server will be appended to the stat name, unless
`append_hostname: false` is specified. So if the namespace is `canvas` and the
hostname is `app01`, the final stat name of `my_stat` would be
`canvas.my_stat.app01` (assuming the default statsd/graphite configuration)


## Usage

Outside of configuration, app code generally interacts with the
`InstStatsd::Statsd` object, which is a proxy class to communicate messages
to statsd.

Available statsd messages are described in:

* [etsty/statsd README](https://github.com/etsy/statsd/blob/master/README.md)
* [reinh/statsd source](https://github.com/reinh/statsd/blob/master/lib/statsd.rb)

So for instance:

```ruby
ms = Benchmark.ms { ..code.. }
InstStatsd::Statsd.timing("my_stat", ms)
```

If statsd isn't configured and enabled, then calls to `InstStatsd::Statsd.*`
will do nothing and return nil.



## Default Metrics Tracking

InstStatsd ships with a several trackers that can capture
several performance metrics. To enable these default metrics
tracking in your rails app, you enable the ones you want, and
then enable request tracking:

```ruby
# config/initializers/inst_statsd.rb
InstStatsd::DefaultTracking.track_sql
InstStatsd::DefaultTracking.track_cache
InstStatsd::DefaultTracking.track_active_record
InstStatsd::RequestTracking.enable
```

This will track the following (as statsd
timings) per request:

| Metric Type   | Statsd key                      | Description                               |
| -----------   | --------------------------      | ---------------------------------         |
| total         | controller.action.total         | total time spent on controller action*    |
| db            | controller.action.db            | time spent in the db*                     |
| view          | controller.action.view          | time spent build views*                   |
| sql write     | controller.action.sql.write     | number of sql writes                      |
| sql read      | controller.action.sql.read      | number of sql reads                       |
| sql cache     | controller.action.sql.cache     | number of sql cache                       |
| active record | controller.action.active_record | number of ActiveRecord objects created ** |
| cache read    | controller.action.cache.read    | number of cache reads                     |


\* as reported by [`ActiveSupport::Notifications`](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html)

\** as reported by [`aroi`](https://github.com/knomedia/aroi)

If you'd like InstStatsd to log these metrics (as well as sending them to statsd), pass a logger object along like so:

```ruby
# log default metrics to environment logs in Rails
InstStatsd::RequestTracking.enable logger: Rails.logger
```
## Block tracking

You can easily track the performance of any block of code using all enabled
metrics. Just be careful that your key isn't too dynamic, causing performance problems
for your statsd server.

```ruby
InstStatsd::DefaultTracking.track_sql
InstStatsd::DefaultTracking.track_cache
InstStatsd::DefaultTracking.track_active_record
InstStatsd::BlockTracking.track("my_important_job") do
  sleep(10)
end
```

If you want to keep track of both exclusive and inclusive times for a re-entrant piece of code,
you just need to tell InstStatsd which category to track along:

```ruby
InstStatsd::BlockTracking.track("my_important_job", category: :my_stuff) do
  sleep(10)
  InstStatsd::BlockTracking.track("my_other_important_job", category: :my_stuff) do
    sleep(5)
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
