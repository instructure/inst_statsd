# frozen_string_literal: true

require "spec_helper"
require "datadog/statsd"

RSpec.describe InstStatsd::Event do
  include described_class

  let(:title) { "Title" }
  let(:text) { "Some text." }

  let(:instance) { instance_double(Datadog::Statsd) }
  let(:data_dog?) { true }
  let(:dog_tags) { {} }
  let(:opts) { {} }

  describe "#feature_event" do
    subject { feature_event(title, text, **opts) }

    context "with title and text only" do
      let(:opts) { {} }

      it 'invokes "event" on the instance with title and text' do
        expect(instance).to receive(:event).with(
          title,
          text,
          alert_type: :success,
          priority: :normal,
          tags: { type: InstStatsd::Event::FEATURE_EVENT }
        )

        subject
      end
    end

    context "with all opts set" do
      let(:date_happened) { Time.now.to_i }
      let(:opts) do
        {
          date_happened: date_happened,
          tags: { foo: "bar" }
        }
      end

      it "sets all arguments" do
        expect(instance).to receive(:event).with(
          title,
          text,
          alert_type: :success,
          priority: :normal,
          date_happened: date_happened,
          tags: { foo: "bar", type: InstStatsd::Event::FEATURE_EVENT }
        )

        subject
      end
    end
  end

  describe "#event" do
    subject { event(title, text, **opts) }

    context "with title and text only" do
      let(:opts) { {} }

      it 'invokes "event" on the instance with title and text' do
        expect(instance).to receive(:event).with(
          title,
          text,
          tags: {}
        )

        subject
      end
    end

    context "with alert_type set" do
      let(:opts) { { alert_type: :error } }

      it 'invokes "event" on the instance with expected arguments' do
        expect(instance).to receive(:event).with(
          title,
          text,
          alert_type: :error,
          tags: {}
        )

        subject
      end
    end

    context "with priority set" do
      let(:opts) { { priority: :low } }

      it 'invokes "event" on the instance with expected arguments' do
        expect(instance).to receive(:event).with(
          title,
          text,
          priority: :low,
          tags: {}
        )

        subject
      end
    end

    context "with date_happened set" do
      let(:opts) { { date_happened: date_happened } }
      let(:date_happened) { Time.now.to_i }

      it 'invokes "event" on the instance with expected arguments' do
        expect(instance).to receive(:event).with(
          title,
          text,
          date_happened: date_happened,
          tags: {}
        )

        subject
      end
    end

    context "with a valid type set" do
      let(:opts) { { type: InstStatsd::Event::DEPLOY_EVENT } }

      it "sets the valid aggregation key" do
        expect(instance).to receive(:event).with(
          title,
          text,
          tags: { type: InstStatsd::Event::DEPLOY_EVENT }
        )

        subject
      end
    end

    context "with a valid type set as a string" do
      let(:opts) { { type: "deploy" } }

      it "sets the valid aggregation key" do
        expect(instance).to receive(:event).with(
          title,
          text,
          tags: { type: InstStatsd::Event::DEPLOY_EVENT }
        )

        subject
      end
    end

    context "with custom tags" do
      let(:opts) { { tags: { project: "cool-project" } } }

      it 'invokes "event" on the instance with expected arguments' do
        expect(instance).to receive(:event).with(
          title,
          text,
          tags: { project: "cool-project" }
        )

        subject
      end
    end

    context "with all opts set" do
      let(:date_happened) { Time.now.to_i }
      let(:opts) do
        {
          type: InstStatsd::Event::DEPLOY_EVENT,
          alert_type: :warning,
          priority: :low,
          date_happened: date_happened,
          tags: { foo: "bar" }
        }
      end

      it "sets all arguments" do
        expect(instance).to receive(:event).with(
          title,
          text,
          alert_type: :warning,
          priority: :low,
          date_happened: date_happened,
          tags: { foo: "bar", type: InstStatsd::Event::DEPLOY_EVENT }
        )

        subject
      end
    end

    context "when the instance is not DataDog" do
      let(:data_dog?) { false }

      it { is_expected.to be_nil }

      it 'does not invoke "event" on the instance' do
        expect(instance).not_to receive(:event)

        subject
      end
    end
  end
end
