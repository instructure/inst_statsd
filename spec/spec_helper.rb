require 'canvas_statsd'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.raise_errors_for_deprecations!

  config.order = 'random'
end
