# frozen_string_literal: true

require "spec_helper"

describe InstStatsd::RequestTracking do
  describe "#enable" do
    it "should delegate log messages to the optional logger" do
      log_double = instance_double(Logger)
      expect(log_double).to receive(:info)
      InstStatsd::RequestTracking.enable logger: log_double
      InstStatsd::RequestTracking.send(:start_processing)
      InstStatsd::RequestTracking.send(:finalize_processing, "name", 1000, 10_001, 1234, {})
    end
  end
end
