# frozen_string_literal: true

require 'spec_helper'

describe InstStatsd::RequestTracking do

  describe '#enable' do
    it 'should delegate log messages to the optional logger' do
      log_double = double()
      expect(log_double).to receive(:info)
      InstStatsd::RequestTracking.enable logger: log_double
      InstStatsd::RequestTracking.start_processing
      InstStatsd::RequestTracking.finalize_processing('name', 1000, 10001, 1234, {})
    end
  end
end
