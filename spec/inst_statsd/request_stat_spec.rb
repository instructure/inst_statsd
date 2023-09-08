# frozen_string_literal: true

require "spec_helper"

def create_subject(payload = {}, statsd = nil)
  args = ["name", 1000, 1001, 1234, payload]
  args << statsd if statsd
  InstStatsd::RequestStat.new(*args)
end

describe InstStatsd::RequestStat do
  describe "#db_runtime" do
    it "should return the payload db_runtime" do
      rs = create_subject({ db_runtime: 11.11 })
      expect(rs.db_runtime).to eq 11.11
    end

    it "should return nil when payload db_runtime key doesnt exists" do
      rs = create_subject
      expect(rs.db_runtime).to be_nil
    end
  end

  describe "#view_runtime" do
    it "should return the payload view_runtime" do
      rs = create_subject(view_runtime: 11.11)
      expect(rs.view_runtime).to eq 11.11
    end

    it "should return nil when payload view_runtime key doesnt exists" do
      rs = create_subject
      expect(rs.view_runtime).to be_nil
    end
  end

  describe "#controller" do
    it "should return params['controller']" do
      rs = create_subject({ params: { "controller" => "foo" } })
      expect(rs.controller).to eq "foo"
    end

    it "should return nil if no params are available" do
      rs = create_subject
      expect(rs.controller).to be_nil
    end

    it "should return nil if no controller is available on params" do
      rs = create_subject({ params: {} })
      expect(rs.controller).to be_nil
    end
  end

  describe "#action" do
    it "should return params['action']" do
      rs = create_subject({ params: { "action" => "index" } })
      expect(rs.action).to eq "index"
    end

    it "should return nil if no params are available" do
      rs = create_subject
      expect(rs.action).to be_nil
    end

    it "should return nil if no action is available on params" do
      rs = create_subject({ params: {} })
      expect(rs.action).to be_nil
    end
  end

  describe "#status" do
    it "should return nil if status is not defined" do
      rs = create_subject
      expect(rs.status).to be_nil
    end

    it "should return HTTP status group if present" do
      expect(create_subject({ status: 200 }).status).to eq "2XX"
      expect(create_subject({ status: 201 }).status).to eq "2XX"
      expect(create_subject({ status: 302 }).status).to eq "3XX"
      expect(create_subject({ status: 400 }).status).to eq "4XX"
      expect(create_subject({ status: 404 }).status).to eq "4XX"
      expect(create_subject({ status: 503 }).status).to eq "5XX"
    end
  end

  describe "#total" do
    it "correctly calculates milliseconds from start, finish" do
      rs = create_subject({ params: {} })
      # start and finish are in seconds
      expect(rs.total).to eq 1000
    end

    it "defaults to zero if either start or finish are nil" do
      rs = InstStatsd::RequestStat.new("name", nil, 1001, 1111, { params: {} })
      expect(rs.total).to eq 0
      rs = InstStatsd::RequestStat.new("name", 1, nil, 1111, { params: {} })
      expect(rs.total).to eq 0
    end
  end

  describe "#report" do
    it "doesnt send stats when no controller or action" do
      statsd = InstStatsd::Statsd
      rs = create_subject({ params: {} }, statsd)
      expect(statsd).not_to receive(:timing).with("request.foo.index", 1000, { short_stat: nil, tags: {} })
      rs.report
    end

    it "sends total timing when controller && action are present, doesnt send db, or view if they are not" do
      statsd = InstStatsd::Statsd
      payload = {
        params: {
          "controller" => "foo",
          "action" => "index"
        }
      }
      rs = create_subject(payload, statsd)
      expect(statsd).to receive(:timing).with("request.foo.index.total", 1000, { short_stat: ".total", tags: {} })
      rs.report
    end

    it "sends total timing when controller && action are present as tags for data dog" do
      statsd = InstStatsd::Statsd
      expect(statsd).to receive(:data_dog?).and_return true
      payload = {
        params: {
          "controller" => "foo",
          "action" => "index"
        },
        status: 200
      }
      rs = create_subject(payload, statsd)
      expect(statsd).to receive(:timing).with("request.total",
                                              1000,
                                              { short_stat: "request.total",
                                                tags: { action: "index", controller: "foo", status: "2XX" } })
      rs.report
    end

    it "sends view_runtime and db_runtime when present" do
      statsd = InstStatsd::Statsd
      payload = {
        view_runtime: 70.1,
        db_runtime: 100.2,
        params: {
          "controller" => "foo",
          "action" => "index"
        }
      }
      rs = create_subject(payload, statsd)
      allow(statsd).to receive(:timing).with("request.foo.index.total", 1000, { short_stat: ".total", tags: {} })
      expect(statsd).to receive(:timing).with("request.foo.index.view", 70.1, { short_stat: ".view", tags: {} })
      expect(statsd).to receive(:timing).with("request.foo.index.db", 100.2, { short_stat: ".db", tags: {} })
      rs.report
    end

    describe "sql stats" do
      before do
        @statsd = InstStatsd::Statsd
        payload = {
          params: {
            "controller" => "foo",
            "action" => "index"
          }
        }
        @rs = create_subject(payload, @statsd)
        @rs.stats["cache.read"] = 25
        expect(@statsd).to receive(:timing).with("request.foo.index.cache.read",
                                                 25,
                                                 { short_stat: ".cache.read", tags: {} })
      end

      it "doesnt send sql stats when they dont exist" do
        allow(@statsd).to receive(:timing).with("request.foo.index.total", 1000, { short_stat: nil, tags: {} })
        expect(@statsd).not_to receive(:timing).with("request.foo.index.sql.read",
                                                     kind_of(Numeric),
                                                     { short_stat: ".sql.read", tags: {} })
        expect(@statsd).not_to receive(:timing).with("request.foo.index.sql.write",
                                                     kind_of(Numeric),
                                                     { short_stat: ".sql.write", tags: {} })
        expect(@statsd).not_to receive(:timing).with("request.foo.index.sql.cache",
                                                     kind_of(Numeric),
                                                     { short_stat: ".sql.cache", tags: {} })
        @rs.report
      end

      it "sends sql_read_count when present" do
        @rs.stats["sql.read"] = 10
        allow(@statsd).to receive(:timing).with("request.foo.index.total", 1000, { short_stat: ".total", tags: {} })
        expect(@statsd).to receive(:timing).with("request.foo.index.sql.read",
                                                 10,
                                                 { short_stat: ".sql.read", tags: {} })
        @rs.report
      end
    end
  end
end
