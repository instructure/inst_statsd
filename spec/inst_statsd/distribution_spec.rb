# frozen_string_literal: true

require "spec_helper"
require "datadog/statsd"

RSpec.describe InstStatsd::Distribution do
  let(:instance) { instance_double(Datadog::Statsd) }
  let(:append_hostname) { false }

  before do
    allow(InstStatsd::Statsd).to receive_messages(
      data_dog?: is_datadog,
      dog_tags: dog_tags,
      instance: instance,
      append_hostname?: append_hostname
    )
  end

  describe ".distribution" do
    subject { InstStatsd::Statsd.distribution(metric, value, tags: tags) }

    let(:metric) { "client.request.failed" }
    let(:value) { 23 }
    let(:tags) { { status: "500" } }

    context "when instance and data_dog? are configured" do
      let(:dog_tags) { { environment: "production" } }
      let(:is_datadog) { true }

      it 'invokes "distribution" on the instance with metric, value, and tags' do
        expect(instance).to receive(:distribution).with(
          metric,
          value,
          { tags: ["status:500", "environment:production", "host:"] }
        )

        subject
      end

      it "handles an array of tags" do
        expect(instance).to receive(:distribution).with(
          metric,
          value,
          { tags: ["status:500", "host:"] }
        )
        InstStatsd::Statsd.distribution(metric, value, tags: ["status:500"])
      end

      context "when the tags are nil" do
        let(:tags) { nil }

        it "handles nil tags" do
          expect(instance).to receive(:distribution).with(
            metric,
            value,
            { tags: ["environment:production", "host:"] }
          )

          subject
        end
      end

      context "when append_hostname? is true" do
        let(:append_hostname) { true }

        it "appends the hostname to the metric and excludes a host tag" do
          expect(instance).to receive(:distribution).with(
            "#{metric}.#{Socket.gethostname}",
            value,
            { tags: ["status:500", "environment:production"] }
          )

          subject
        end
      end
    end

    context "when instance and data_dog? are not configured" do
      let(:dog_tags) { {} }
      let(:is_datadog) { false }

      it "does nothing" do
        expect(instance).not_to receive(:distribution)

        subject
      end
    end
  end

  describe ".distributed_increment" do
    subject { InstStatsd::Statsd.distributed_increment(metric, tags: tags) }

    let(:metric) { "client.request.failed" }
    let(:tags) { { status: "500" } }
    let(:dog_tags) { { status: "401" } }
    let(:is_datadog) { true }

    before do
      allow(InstStatsd::Statsd).to receive_messages(distribution: nil)
    end

    it 'invokes "distribution" on InstStatsd::Statsd with metric, 1, and tags' do
      expect(InstStatsd::Statsd).to receive(:distribution).with(metric, 1, tags: ["status:401", "host:"])

      subject
    end

    context "when append_hostname? is true" do
      let(:append_hostname) { true }

      it "appends the hostname to the metric and excludes a host tag" do
        expect(InstStatsd::Statsd).to receive(:distribution).with(
          "#{metric}.#{Socket.gethostname}",
          1,
          { tags: ["status:401"] }
        )

        subject
      end
    end

    context "when the configured instance is not a DataDog instance" do
      let(:dog_tags) { {} }
      let(:is_datadog) { false }

      it 'invokes "increment" on InstStatsd::Statsd with metric and tags' do
        expect(InstStatsd::Statsd).to receive(:increment).with(metric, tags: tags, short_stat: nil)

        subject
      end
    end
  end
end
