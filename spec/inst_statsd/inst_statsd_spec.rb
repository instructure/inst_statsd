# frozen_string_literal: true

require 'spec_helper'

describe InstStatsd do
  before(:each) do
    InstStatsd.settings = nil
  end

  after(:each) do
    [
      'INST_STATSD_HOST',
      'INST_STATSD_NAMESPACE',
      'INST_STATSD_PORT',
      'INST_STATSD_APPEND_HOST_NAME',
      'INST_DOG_TAGS'
    ].each {|k| ENV.delete k}
  end

  describe ".settings" do
    it "have default settings" do
      expect(InstStatsd.settings).to eq({})
    end

    it "can be assigned a new value" do
      settings = { host: 'bar', port: 1234 }
      InstStatsd.settings = settings

      expect(InstStatsd.settings).to eq settings
    end

    it 'pulls from ENV if not already set' do
      ENV['INST_STATSD_HOST'] = 'statsd.example.org'
      ENV['INST_STATSD_NAMESPACE'] = 'canvas'

      expected = {
        host: 'statsd.example.org',
        namespace: 'canvas',
      }
      expect(InstStatsd.settings).to eq(expected)
    end

    it 'configured settings are merged into and take precedence over any existing ENV settings' do
      ENV['INST_STATSD_HOST'] = 'statsd.example.org'
      ENV['INST_STATSD_NAMESPACE'] = 'canvas'

      settings = { host: 'statsd.example-override.org' }
      InstStatsd.settings = settings

      expect(InstStatsd.settings).to eq(InstStatsd.env_settings.merge(settings))
      expect(InstStatsd.settings[:host]).to eq(settings[:host])
    end

    it 'validates settings' do
      settings = { foo: 'blah' }
      expect { InstStatsd.settings = settings }.to raise_error(InstStatsd::ConfigurationError)
    end

    it 'converts string keys to symbols' do
      settings = { 'host' => 'bar', 'port' => 1234 }
      InstStatsd.settings = settings
      expect(InstStatsd.settings).to eq({ host: 'bar', port: 1234 })
    end
  end

  describe ".convert_bool" do
    it 'sets string true values to boolean true' do
      config = {potential_string_bool: 'true'}
      InstStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(true)
    end
    it 'sets string True values to boolean true' do
      config = {potential_string_bool: 'True'}
      InstStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(true)
    end
    it 'sets boolean true values to boolean true' do
      config = {potential_string_bool: true}
      InstStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(true)
    end
    it 'sets false strings to boolean false' do
      config = {potential_string_bool: 'false'}
      InstStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(false)
    end
    it 'sets False strings to boolean false' do
      config = {potential_string_bool: 'False'}
      InstStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(false)
    end
    it 'sets false booleans to boolean false' do
      config = {potential_string_bool: false}
      InstStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(false)
    end
    it 'makes no change for nil values' do
      config = {foo: 'bar'}
      InstStatsd.convert_bool(config, :potential_string_bool)
      expect(config).to eq({foo: 'bar'})
    end
    it 'raises error for non true or false strings or booleans' do
      config = {potential_string_bool: 'trrruuue'}
      expect{InstStatsd.convert_bool(config, :potential_string_bool)}.to raise_error(InstStatsd::ConfigurationError)
    end

  end

  describe ".env_settings" do
    it 'returns empty hash when no INST_STATSD_HOST found' do
      env = {
        'INST_STATSD_NAMESPACE' => 'canvas'
      }
      expect(InstStatsd.env_settings(env)).to eq({})
    end

    it 'returns empty hash when missing dog tags' do
      env = {
        'INST_DOG_API_KEY' => 'SEKRET KEY'
      }
      expect(InstStatsd.env_settings(env)).to eq({})
    end

    it 'builds settings hash with dog environment vars' do
      env = {
        'INST_DOG_TAGS' => '{"app": "canvas", "env": "prod"}',
      }
      expected = {
        dog_tags: {"app" => "canvas", "env" => "prod"},
      }
      expect(InstStatsd.env_settings(env)).to eq(expected)
    end

    it 'builds settings hash from environment vars' do
      env = {
        'INST_STATSD_HOST' => 'statsd.example.org',
        'INST_STATSD_NAMESPACE' => 'canvas',
      }
      expected = {
        host: 'statsd.example.org',
        namespace: 'canvas',
      }
      expect(InstStatsd.env_settings(env)).to eq(expected)
    end

    it 'uses ENV if env argument hash not passed' do
      ENV['INST_STATSD_HOST'] = 'statsd.example.org'
      ENV['INST_STATSD_NAMESPACE'] = 'canvas'

      expected = {
        host: 'statsd.example.org',
        namespace: 'canvas',
      }
      expect(InstStatsd.env_settings).to eq(expected)
    end

    it 'converts env append_hostname "false" to boolean' do
      env = {
        'INST_STATSD_HOST' => 'statsd.example.org',
        'INST_STATSD_APPEND_HOSTNAME' => 'false',
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: false,
      }
      expect(InstStatsd.env_settings(env)).to eq(expected)
    end

    it 'converts env append_hostname "true" to boolean' do
      env = {
        'INST_STATSD_HOST' => 'statsd.example.org',
        'INST_STATSD_APPEND_HOSTNAME' => 'true',
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: true,
      }
      expect(InstStatsd.env_settings(env)).to eq(expected)
    end

    it 'keeps boolean false values for append_hostname' do
      env = {
        'INST_STATSD_HOST' => 'statsd.example.org',
        'INST_STATSD_APPEND_HOSTNAME' => false,
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: false,
      }
      expect(InstStatsd.env_settings(env)).to eq(expected)
    end

    it 'keeps boolean true values for append_hostname' do
      env = {
        'INST_STATSD_HOST' => 'statsd.example.org',
        'INST_STATSD_APPEND_HOSTNAME' => true,
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: true,
      }
      expect(InstStatsd.env_settings(env)).to eq(expected)
    end

  end

end
