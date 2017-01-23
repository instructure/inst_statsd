require 'spec_helper'

describe CanvasStatsd::RequestTracking do

  describe '#enable' do
    it 'should delegate log messages to the optional logger' do
      log_double = double()
      expect(log_double).to receive(:info)
      CanvasStatsd::RequestTracking.enable logger: log_double
      CanvasStatsd::RequestTracking.start_processing
      CanvasStatsd::RequestTracking.finalize_processing('name', 1000, 10001, 1234, {})
    end
  end
end
