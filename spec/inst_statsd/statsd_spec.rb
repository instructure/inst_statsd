# frozen_string_literal: true

require "spec_helper"

require "datadog/statsd"

describe InstStatsd::Statsd do
  let(:methods) { %w[increment decrement count gauge timing].freeze }
  let(:increment_decrement) { %w[increment decrement].freeze }

  after do
    InstStatsd.settings = {}
    InstStatsd::Statsd.reset_instance
  end

  it "includes the events module" do
    expect(described_class).to respond_to :event
  end

  it "appends the hostname to stat names by default" do
    statsd = instance_double(Datadog::Statsd)
    allow(InstStatsd::Statsd).to receive_messages(hostname: "testhost", instance: statsd, append_hostname?: true)
    methods.each do |method|
      expect(statsd).to receive(method).with("test.name.testhost", "test")
      InstStatsd::Statsd.send(method, "test.name", "test")
    end
    expect(statsd).to receive("timing").with("test.name.testhost", anything, anything)
    expect(InstStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "sending tags should not break statsd" do
    default_tags = { app: "canvas", env: "prod" }
    short_stat = "test2"
    env = {
      "INST_DOG_TAGS" => '{"app": "canvas", "env": "prod"}'
    }
    InstStatsd.env_settings(env)
    statsd = instance_double(Datadog::Statsd)
    allow(InstStatsd::Statsd).to receive_messages(hostname: "testhost",
                                                  short_stat: short_stat,
                                                  instance: statsd,
                                                  data_dog?: false,
                                                  append_hostname?: true)
    methods.each do |method|
      expect(statsd).to receive(method).with("test.name.testhost", "test") # no short stat or tags
      InstStatsd::Statsd.send(method, "test.name", "test", short_stat: short_stat, tags: default_tags)
    end
    expect(statsd).to receive("timing").with("test.name.testhost", anything, anything) # no short stat or tags
    expect(InstStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "adds default dog tags default" do
    default_tags = { app: "canvas", env: "prod" }
    converted_tags = ["app:canvas", "env:prod", "host:"]
    short_stat = "test2"
    statsd = instance_double(Datadog::Statsd)
    allow(InstStatsd::Statsd).to receive_messages(dog_tags: default_tags,
                                                  short_stat: short_stat,
                                                  instance: statsd,
                                                  data_dog?: true,
                                                  append_hostname?: false)
    methods.each do |method|
      args = [short_stat]
      args << "test" unless increment_decrement.include?(method)

      expect(statsd).to receive(method).with(*args, { tags: converted_tags })
      InstStatsd::Statsd.send(method, *args, short_stat: short_stat)
    end
    expect(statsd).to receive("timing").with(short_stat, anything, { sample_rate: anything, tags: converted_tags })
    expect(InstStatsd::Statsd.time("test.name", short_stat: short_stat) { "test" }).to eq "test"
  end

  it "uses regular stat name when short_stat is omitted on data dog" do
    default_tags = { app: "canvas", env: "prod" }
    converted_tags = ["app:canvas", "env:prod", "host:"]
    statsd = instance_double(Datadog::Statsd)
    allow(InstStatsd::Statsd).to receive_messages(dog_tags: default_tags,
                                                  instance: statsd,
                                                  data_dog?: true,
                                                  append_hostname?: false)
    methods.each do |method|
      args = ["test.name"]
      args << "test" unless increment_decrement.include?(method)

      expect(statsd).to receive(method).with(*args, { tags: converted_tags })
      InstStatsd::Statsd.send(method, *args)
    end
    expect(statsd).to receive("timing").with("test.name", anything, { sample_rate: anything, tags: converted_tags })
    expect(InstStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "omits hostname if specified in config" do
    expect(InstStatsd::Statsd).not_to receive(:hostname)
    statsd = instance_double(Datadog::Statsd)
    allow(InstStatsd::Statsd).to receive_messages(instance: statsd, append_hostname?: false)
    methods.each do |method|
      expect(statsd).to receive(method).with("test.name", "test")
      InstStatsd::Statsd.send(method, "test.name", "test")
    end
    expect(statsd).to receive("timing").with("test.name", anything, anything)
    expect(InstStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  context "with datadog enabled" do
    it "handles being called with an array of stat names" do
      converted_tags = %w[tag:value host:]
      statsd = instance_double(Datadog::Statsd)
      allow(InstStatsd::Statsd).to receive_messages(instance: statsd, append_hostname?: false, data_dog?: true)
      methods.each do |method|
        args = []
        args << "values" unless increment_decrement.include?(method)

        expect(statsd).to receive(method).once.with("test.one", *args, { tags: converted_tags })
        expect(statsd).to receive(method).once.with("test.two", *args, { tags: converted_tags })
        InstStatsd::Statsd.send(method,
                                %w[test.one test.two],
                                *args,
                                tags: { tag: "value" },
                                short_stat: "short_stat")
      end
      expect(statsd).to receive("timing").once.with("test.one",
                                                    anything,
                                                    { tags: converted_tags, sample_rate: anything })
      expect(statsd).to receive("timing").once.with("test.two",
                                                    anything,
                                                    { tags: converted_tags, sample_rate: anything })
      expect(InstStatsd::Statsd.time(%w[test.one test.two], tags: { tag: "value" }, short_stat: "short_stat") do
               "test"
             end).to eq "test"
    end
  end

  it "ignores all calls if statsd isn't enabled" do
    allow(InstStatsd::Statsd).to receive(:instance).and_return(nil)
    methods.each do |method|
      expect(InstStatsd::Statsd.send(method, "test.name")).to be_nil
    end
    expect(InstStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "configures a statsd instance" do
    expect(InstStatsd::Statsd.instance).to be_nil

    InstStatsd.settings = { host: "localhost", namespace: "test", port: 1234 }
    InstStatsd::Statsd.reset_instance

    instance = InstStatsd::Statsd.instance
    expect(instance).to be_a Statsd
    expect(instance.host).to eq "localhost"
    expect(instance.port).to eq 1234
    expect(instance.namespace).to eq "test"
  end

  describe ".batch" do
    it "is properly reentrant" do
      InstStatsd.settings = { host: "localhost", namespace: "test", port: 1234 }
      InstStatsd::Statsd.reset_instance

      statsd = InstStatsd::Statsd.instance
      InstStatsd::Statsd.batch do
        batch1 = InstStatsd::Statsd.instance
        InstStatsd::Statsd.batch do
          batch2 = InstStatsd::Statsd.instance
          expect(statsd).to be_a Statsd
          expect(batch1).to be_a Statsd::Batch
          expect(batch2).to be_a Statsd::Batch
          expect(batch1).not_to eq batch2
        end
        expect(InstStatsd::Statsd.instance).to eq batch1
      end
      expect(InstStatsd::Statsd.instance).to eq statsd
    end
  end

  describe ".escape" do
    it "replaces any dots in str with a _ when no replacment given" do
      result = InstStatsd::Statsd.escape("lots.of.dots")
      expect(result).to eq "lots_of_dots"
    end

    it "replaces any dots in str with replacement arg" do
      result = InstStatsd::Statsd.escape("lots.of.dots", "/")
      expect(result).to eq "lots/of/dots"
    end

    it "returns str when given a str that doesnt respond to gsub" do
      result = InstStatsd::Statsd.escape(nil)
      expect(result).to be_nil
      hash = { foo: "bar" }
      result = InstStatsd::Statsd.escape(hash)
      expect(result).to eq hash
    end
  end
end
