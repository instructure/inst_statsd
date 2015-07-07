#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

describe CanvasStatsd do
  before(:each) do
    CanvasStatsd.settings = {}
  end

  after(:each) do
    [
      'CANVAS_STATSD_HOST',
      'CANVAS_STATSD_NAMESPACE',
      'CANVAS_STATSD_PORT',
      'CANVAS_STATSD_APPEND_HOST_NAME',
    ].each {|k| ENV.delete k}
  end

  describe ".settings" do
    it "have default settings" do
      expect(CanvasStatsd.settings).to eq({})
    end

    it "can be assigned a new value" do
      settings = {foo: 'bar', baz: 'apple'}
      CanvasStatsd.settings = settings

      expect(CanvasStatsd.settings).to eq settings
    end

    it 'pulls from ENV if not already set' do
      ENV['CANVAS_STATSD_HOST'] = 'statsd.example.org'
      ENV['CANVAS_STATSD_NAMESPACE'] = 'canvas'

      expected = {
        host: 'statsd.example.org',
        namespace: 'canvas',
      }
      expect(CanvasStatsd.settings).to eq(expected)

    end

    it 'configured settings are merged into and take precedence over any existing ENV settings' do
      ENV['CANVAS_STATSD_HOST'] = 'statsd.example.org'
      ENV['CANVAS_STATSD_NAMESPACE'] = 'canvas'

      settings = {foo: 'bar', baz: 'apple', host: 'statsd.example-override.org'}
      CanvasStatsd.settings = settings

      expect(CanvasStatsd.settings).to eq(CanvasStatsd.env_settings.merge(settings))
      expect(CanvasStatsd.settings[:host]).to eq(settings[:host])
    end
  end

  describe ".convert_bool" do
    it 'sets string true values to boolean true' do
      config = {potential_string_bool: 'true'}
      CanvasStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(true)
    end
    it 'sets string True values to boolean true' do
      config = {potential_string_bool: 'True'}
      CanvasStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(true)
    end
    it 'sets boolean true values to boolean true' do
      config = {potential_string_bool: true}
      CanvasStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(true)
    end
    it 'sets false strings to boolean false' do
      config = {potential_string_bool: 'false'}
      CanvasStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(false)
    end
    it 'sets False strings to boolean false' do
      config = {potential_string_bool: 'False'}
      CanvasStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(false)
    end
    it 'sets false booleans to boolean false' do
      config = {potential_string_bool: false}
      CanvasStatsd.convert_bool(config, :potential_string_bool)
      expect(config[:potential_string_bool]).to be(false)
    end
    it 'makes no change for nil values' do
      config = {foo: 'bar'}
      CanvasStatsd.convert_bool(config, :potential_string_bool)
      expect(config).to eq({foo: 'bar'})
    end
    it 'raises error for non true or false strings or booleans' do
      config = {potential_string_bool: 'trrruuue'}
      expect{CanvasStatsd.convert_bool(config, :potential_string_bool)}.to raise_error(CanvasStatsd::ConfigurationError)
    end

  end

  describe ".env_settings" do
    it 'returns empty hash when no CANVAS_STATSD_HOST found' do
      env = {
        'CANVAS_STATSD_NAMESPACE' => 'canvas'
      }
      expect(CanvasStatsd.env_settings(env)).to eq({})
    end

    it 'builds settings hash from environment vars' do
      env = {
        'CANVAS_STATSD_HOST' => 'statsd.example.org',
        'CANVAS_STATSD_NAMESPACE' => 'canvas',
      }
      expected = {
        host: 'statsd.example.org',
        namespace: 'canvas',
      }
      expect(CanvasStatsd.env_settings(env)).to eq(expected)
    end

    it 'uses ENV if env argument hash not passed' do
      ENV['CANVAS_STATSD_HOST'] = 'statsd.example.org'
      ENV['CANVAS_STATSD_NAMESPACE'] = 'canvas'

      expected = {
        host: 'statsd.example.org',
        namespace: 'canvas',
      }
      expect(CanvasStatsd.env_settings).to eq(expected)
    end

    it 'converts env append_hostname "false" to boolean' do
      env = {
        'CANVAS_STATSD_HOST' => 'statsd.example.org',
        'CANVAS_STATSD_APPEND_HOSTNAME' => 'false',
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: false,
      }
      expect(CanvasStatsd.env_settings(env)).to eq(expected)
    end

    it 'converts env append_hostname "true" to boolean' do
      env = {
        'CANVAS_STATSD_HOST' => 'statsd.example.org',
        'CANVAS_STATSD_APPEND_HOSTNAME' => 'true',
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: true,
      }
      expect(CanvasStatsd.env_settings(env)).to eq(expected)
    end

    it 'keeps boolean false values for append_hostname' do
      env = {
        'CANVAS_STATSD_HOST' => 'statsd.example.org',
        'CANVAS_STATSD_APPEND_HOSTNAME' => false,
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: false,
      }
      expect(CanvasStatsd.env_settings(env)).to eq(expected)
    end

    it 'keeps boolean true values for append_hostname' do
      env = {
        'CANVAS_STATSD_HOST' => 'statsd.example.org',
        'CANVAS_STATSD_APPEND_HOSTNAME' => true,
      }
      expected = {
        host: 'statsd.example.org',
        append_hostname: true,
      }
      expect(CanvasStatsd.env_settings(env)).to eq(expected)
    end

  end

end
