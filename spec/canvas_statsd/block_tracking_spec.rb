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

  context "mask" do
    after do
      CanvasStatsd::BlockTracking.mask = nil
      CanvasStatsd::BlockTracking.negative_mask = nil
    end

    it "only tracks keys that match the mask" do
      CanvasStatsd::BlockTracking.mask = /mykey/
      statsd = double()
      allow(statsd).to receive(:timing).with('mykey.total', anything)
      expect(statsd).to receive(:timing).with("mykey.sql.read", 1)

      CanvasStatsd::BlockTracking.track("mykey", statsd: statsd, only: 'sql.read') do
        CanvasStatsd::BlockTracking.track("ignoreme", statsd: statsd, only: 'sql.read') do
          ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        end
      end
    end

    it "doesn't track keys that match the negative mask" do
      CanvasStatsd::BlockTracking.negative_mask = /ignoreme/
      statsd = double()
      allow(statsd).to receive(:timing).with('mykey.total', anything)
      expect(statsd).to receive(:timing).with("mykey.sql.read", 1)

      CanvasStatsd::BlockTracking.track("mykey", statsd: statsd, only: 'sql.read') do
        CanvasStatsd::BlockTracking.track("ignoreme", statsd: statsd, only: 'sql.read') do
          ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        end
      end
    end
  end
end
