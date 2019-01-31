require 'spec_helper'

describe InstStatsd::BlockTracking do
  before(:all) do
    InstStatsd::DefaultTracking.track_sql
  end

  it "works" do
    statsd = double()
    allow(statsd).to receive(:timing).with('mykey.total', anything, {short_stat: "mykey.total", tags: {}})
    expect(statsd).to receive(:timing).with("mykey.sql.read", 1, {short_stat: "mykey.sql.read", tags: {}})

    InstStatsd::BlockTracking.track("mykey", statsd: statsd, only: 'sql.read') do
      ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
    end
  end

  it "works for data_dog" do
    statsd = double()
    allow(statsd).to receive(:data_dog?).and_return true
    allow(statsd).to receive(:timing).with('mykey.total', anything, {short_stat: "mykey.total", tags: {app: "canvas", env: "prod"}})
    expect(statsd).to receive(:timing).with("mykey.sql.read", 1, {short_stat: "mykey.sql.read", tags: {app: "canvas", env: "prod"}})

    InstStatsd::BlockTracking.track("mykey", statsd: statsd, only: 'sql.read', tags: {app: 'canvas', env: 'prod'}, short_stat: 'mykey') do
      ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
    end
  end

  it "keeps track of exclusive stats too" do
    statsd = double()
    expect(statsd).to receive(:timing).with("mykey.sql.read", 2, {short_stat: "mykey.sql.read", tags: {}}).ordered
    expect(statsd).to receive(:timing).with('mykey.total', anything, {short_stat: "mykey.total", tags: {}}).ordered
    expect(statsd).to receive(:timing).with("mykey.exclusive.sql.read", 2, {short_stat: "mykey.exclusive.sql.read", tags: {}}).ordered
    expect(statsd).to receive(:timing).with('mykey.exclusive.total', anything, {short_stat: "mykey.exclusive.total", tags: {}}).ordered
    expect(statsd).to receive(:timing).with("mykey.sql.read", 2, {short_stat: "mykey.sql.read", tags: {}}).ordered
    expect(statsd).to receive(:timing).with('mykey.total', anything, {short_stat: "mykey.total", tags: {}}).ordered
    expect(statsd).to receive(:timing).with("mykey.exclusive.sql.read", 2, {short_stat: "mykey.exclusive.sql.read", tags: {}}).ordered
    expect(statsd).to receive(:timing).with('mykey.exclusive.total', anything, {short_stat: "mykey.exclusive.total", tags: {}}).ordered
    expect(statsd).to receive(:timing).with("mykey.sql.read", 5, {short_stat: "mykey.sql.read", tags: {}}).ordered
    expect(statsd).to receive(:timing).with('mykey.total', anything, {short_stat: "mykey.total", tags: {}}).ordered
    expect(statsd).to receive(:timing).with("mykey.exclusive.sql.read", 1, {short_stat: "mykey.exclusive.sql.read", tags: {}}).ordered
    expect(statsd).to receive(:timing).with('mykey.exclusive.total', anything, {short_stat: "mykey.exclusive.total", tags: {}}).ordered

    InstStatsd::BlockTracking.track("mykey", category: :nested, statsd: statsd, only: 'sql.read') do
      ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
      InstStatsd::BlockTracking.track("mykey", category: :nested, statsd: statsd, only: 'sql.read') do
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
      end
      InstStatsd::BlockTracking.track("mykey", category: :nested, statsd: statsd, only: 'sql.read') do
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
      end
    end
  end

  context "mask" do
    after do
      InstStatsd::BlockTracking.mask = nil
      InstStatsd::BlockTracking.negative_mask = nil
    end

    it "only tracks keys that match the mask" do
      InstStatsd::BlockTracking.mask = /mykey/
      statsd = double()
      allow(statsd).to receive(:timing).with('mykey.total', anything, {short_stat: "mykey.total", tags: {}})
      expect(statsd).to receive(:timing).with("mykey.sql.read", 1, {short_stat: "mykey.sql.read", tags: {}})

      InstStatsd::BlockTracking.track("mykey", statsd: statsd, only: 'sql.read') do
        InstStatsd::BlockTracking.track("ignoreme", statsd: statsd, only: 'sql.read') do
          ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        end
      end
    end

    it "doesn't track keys that match the negative mask" do
      InstStatsd::BlockTracking.negative_mask = /ignoreme/
      statsd = double()
      allow(statsd).to receive(:timing).with('mykey.total', anything, {short_stat: "mykey.total", tags: {}})
      expect(statsd).to receive(:timing).with("mykey.sql.read", 1, {short_stat: "mykey.sql.read", tags: {}})

      InstStatsd::BlockTracking.track("mykey", statsd: statsd, only: 'sql.read') do
        InstStatsd::BlockTracking.track("ignoreme", statsd: statsd, only: 'sql.read') do
          ActiveSupport::Notifications.instrument('sql.active_record', name: "LOAD", sql: "SELECT * FROM users") {}
        end
      end
    end
  end
end
