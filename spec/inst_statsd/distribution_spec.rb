# frozen_string_literal: true

require "spec_helper"
require "datadog/statsd"

RSpec.describe InstStatsd::Distribution do
  describe ".distribution" do
    subject { InstStatsd::Statsd.distribution(metric, value, tags: tags) }

    let(:instance) { instance_double(Datadog::Statsd) }

    let(:metric) { "client.request.failed" }
    let(:value) { 23 }
    let(:tags) { { status: "500" } }

    before do
      allow(InstStatsd::Statsd).to receive_messages(data_dog?: is_datadog, dog_tags: dog_tags, instance: instance)
    end

    context "when instance and data_dog? are configured" do
      let(:dog_tags) { { environment: "production" } }
      let(:is_datadog) { true }

      it 'invokes "distribution" on the instance with metric, value, and tags' do
        expect(instance).to receive(:distribution).with(
          metric,
          value,
          { tags: { status: "500", environment: "production" } }
        )

        subject
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

    before do
      allow(InstStatsd::Statsd).to receive_messages(distribution: nil)
    end

    it 'invokes "distribution" on InstStatsd::Statsd with metric, 1, and tags' do
      expect(InstStatsd::Statsd).to receive(:distribution).with(metric, 1, tags: tags)

      subject
    end
  end
end
