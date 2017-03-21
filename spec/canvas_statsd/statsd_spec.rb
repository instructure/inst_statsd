#
# Copyright (C) 2012 Instructure, Inc.
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

describe CanvasStatsd::Statsd do
  METHODS = %w(increment decrement count gauge timing)

  after do
    CanvasStatsd.settings = {}
    CanvasStatsd::Statsd.reset_instance
  end

  it "appends the hostname to stat names by default" do
    allow(CanvasStatsd::Statsd).to receive(:hostname).and_return("testhost")
    statsd = double
    allow(CanvasStatsd::Statsd).to receive(:instance).and_return(statsd)
    allow(CanvasStatsd::Statsd).to receive(:append_hostname?).and_return(true)
    METHODS.each do |method|
      expect(statsd).to receive(method).with("test.name.testhost", "test")
      CanvasStatsd::Statsd.send(method, "test.name", "test")
    end
    expect(statsd).to receive("timing").with("test.name.testhost", anything, anything)
    expect(CanvasStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "omits hostname if specified in config" do
    expect(CanvasStatsd::Statsd).to receive(:hostname).never
    statsd = double
    allow(CanvasStatsd::Statsd).to receive(:instance).and_return(statsd)
    allow(CanvasStatsd::Statsd).to receive(:append_hostname?).and_return(false)
    METHODS.each do |method|
      expect(statsd).to receive(method).with("test.name", "test")
      CanvasStatsd::Statsd.send(method, "test.name", "test")
    end
    expect(statsd).to receive("timing").with("test.name", anything, anything)
    expect(CanvasStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "ignores all calls if statsd isn't enabled" do
    allow(CanvasStatsd::Statsd).to receive(:instance).and_return(nil)
    METHODS.each do |method|
      expect(CanvasStatsd::Statsd.send(method, "test.name")).to be_nil
    end
    expect(CanvasStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "configures a statsd instance" do
    expect(CanvasStatsd::Statsd.instance).to be_nil

    CanvasStatsd.settings = { :host => "localhost", :namespace => "test", :port => 1234 }
    CanvasStatsd::Statsd.reset_instance

    instance = CanvasStatsd::Statsd.instance
    expect(instance).to be_a ::Statsd
    expect(instance.host).to eq "localhost"
    expect(instance.port).to eq 1234
    expect(instance.namespace).to eq "test"
  end

  describe ".batch" do
    it "is properly reentrant" do
      CanvasStatsd.settings = { :host => "localhost", :namespace => "test", :port => 1234 }
      CanvasStatsd::Statsd.reset_instance

      statsd = CanvasStatsd::Statsd.instance
      CanvasStatsd::Statsd.batch do
        batch1 = CanvasStatsd::Statsd.instance
        CanvasStatsd::Statsd.batch do
          batch2 = CanvasStatsd::Statsd.instance
          expect(statsd).to be_a ::Statsd
          expect(batch1).to be_a ::Statsd::Batch
          expect(batch2).to be_a ::Statsd::Batch
          expect(batch1).not_to eq batch2
        end
        expect(CanvasStatsd::Statsd.instance).to eq batch1
      end
      expect(CanvasStatsd::Statsd.instance).to eq statsd
    end
  end

  describe ".escape" do
    it "replaces any dots in str with a _ when no replacment given" do
      result = CanvasStatsd::Statsd.escape("lots.of.dots")
      expect(result).to eq "lots_of_dots"
    end

    it "replaces any dots in str with replacement arg" do
      result = CanvasStatsd::Statsd.escape("lots.of.dots", "/")
      expect(result).to eq "lots/of/dots"
    end

    it "returns str when given a str that doesnt respond to gsub" do
      result = CanvasStatsd::Statsd.escape(nil)
      expect(result).to eq nil
      hash = {foo: 'bar'}
      result = CanvasStatsd::Statsd.escape(hash)
      expect(result).to eq hash
    end
  end
end
