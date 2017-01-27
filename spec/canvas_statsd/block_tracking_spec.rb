require 'spec_helper'

describe CanvasStatsd::BlockTracking do
  before(:all) do
    CanvasStatsd::DefaultTracking.track_sql
  end

  it "works" do
    statsd = double()
    allow(statsd).to receive(:timing).with('mykey.total', anything)
    expect(statsd).to receive(:timing).with("mykey.sql.read", 1)

    CanvasStatsd::BlockTracking.track("mykey", statsd: statsd, only: 'sql.read') do
      ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
    end
  end

  it "keeps track of exclusive stats too" do
    statsd = double()
    expect(statsd).to receive(:timing).with("mykey.sql.read", 2).ordered
    expect(statsd).to receive(:timing).with('mykey.total', anything).ordered
    expect(statsd).to receive(:timing).with("mykey.exclusive.sql.read", 2).ordered
    expect(statsd).to receive(:timing).with('mykey.exclusive.total', anything).ordered
    expect(statsd).to receive(:timing).with("mykey.sql.read", 2).ordered
    expect(statsd).to receive(:timing).with('mykey.total', anything).ordered
    expect(statsd).to receive(:timing).with("mykey.exclusive.sql.read", 2).ordered
    expect(statsd).to receive(:timing).with('mykey.exclusive.total', anything).ordered
    expect(statsd).to receive(:timing).with("mykey.sql.read", 5).ordered
    expect(statsd).to receive(:timing).with('mykey.total', anything).ordered
    expect(statsd).to receive(:timing).with("mykey.exclusive.sql.read", 1).ordered
    expect(statsd).to receive(:timing).with('mykey.exclusive.total', anything).ordered

    CanvasStatsd::BlockTracking.track("mykey", category: :nested, statsd: statsd, only: 'sql.read') do
      ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
      CanvasStatsd::BlockTracking.track("mykey", category: :nested, statsd: statsd, only: 'sql.read') do
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
      end
      CanvasStatsd::BlockTracking.track("mykey", category: :nested, statsd: statsd, only: 'sql.read') do
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
      end
    end
  end
end
