require 'spec_helper'

describe CanvasStatsd::BlockTracking do
  before(:all) do
    CanvasStatsd::DefaultTracking.track_sql
  end

  it "works" do
    statsd = double()
    expect(statsd).to receive(:timing).with("mykey.total", anything)
    allow(statsd).to receive(:timing).with("mykey.test", anything)
    allow(statsd).to receive(:timing).with("mykey.active_record", 0)
    expect(statsd).to receive(:timing).with("mykey.sql.read", 1)
    expect(statsd).to receive(:timing).with("mykey.sql.write", 0)
    expect(statsd).to receive(:timing).with("mykey.sql.cache", 0)
    allow(statsd).to receive(:timing).with("mykey.cache.read", 0)

    CanvasStatsd::BlockTracking.track("mykey", statsd: statsd) do
      ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
    end
  end
end
