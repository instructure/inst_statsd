require 'spec_helper'

describe CanvasStatsd::RequestTracking do

  describe '#track_request_metrics' do
    it 'should track timing, sql, and active_record by default' do
      expect(CanvasStatsd::RequestTracking).to receive(:track_timing)
      expect(CanvasStatsd::DefaultTracking).to receive(:track_sql)
      expect(CanvasStatsd::DefaultTracking).to receive(:track_active_record)
      CanvasStatsd::RequestTracking.track_default_metrics
    end

    it 'should not track sql when sql: false option' do
      expect(CanvasStatsd::DefaultTracking).not_to receive(:track_sql)
      CanvasStatsd::RequestTracking.track_default_metrics sql: false
    end

    it 'should not track active_record when active_record: false option' do
      expect(CanvasStatsd::DefaultTracking).not_to receive(:track_active_record)
      CanvasStatsd::RequestTracking.track_default_metrics active_record: false
    end

    it 'should not track cache when cache: false option' do
      expect(CanvasStatsd::DefaultTracking).not_to receive(:track_cache)
      CanvasStatsd::RequestTracking.track_default_metrics cache: false
    end

    it 'should delegate log messages to the optional logger' do
      log_double = double()
      expect(log_double).to receive(:info)
      CanvasStatsd::RequestTracking.track_default_metrics logger: log_double
      CanvasStatsd::RequestTracking.finalize_processing('name', 1000, 10001, 1234, {})
    end
  end
end
