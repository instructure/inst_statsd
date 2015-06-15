require 'spec_helper'
require 'aroi' # ensure aroi is loaded (its only conditionally loaded by default)

describe CanvasStatsd::DefaultTracking do

  describe '#track_default_metrics' do
    it 'should track timing, sql, and active_record by default' do
      expect(CanvasStatsd::DefaultTracking).to receive(:track_timing)
      expect(CanvasStatsd::DefaultTracking).to receive(:track_sql)
      expect(CanvasStatsd::DefaultTracking).to receive(:track_active_record)
      CanvasStatsd::DefaultTracking.track_default_metrics
    end

    it 'should not track sql when sql: false option' do
      expect(CanvasStatsd::DefaultTracking).not_to receive(:track_sql)
      CanvasStatsd::DefaultTracking.track_default_metrics sql: false
    end

    it 'should not track active_record when active_record: false option' do
      expect(CanvasStatsd::DefaultTracking).not_to receive(:track_active_record)
      CanvasStatsd::DefaultTracking.track_default_metrics active_record: false
    end

    it 'should delegate log messages to the optional logger' do
      log_double = double()
      expect(log_double).to receive(:info)
      CanvasStatsd::DefaultTracking.track_default_metrics logger: log_double
      CanvasStatsd::DefaultTracking.finalize_processing('name', 1000, 10001, 1234, {})
    end
  end

  describe '#track_active_record' do
    it 'should turn on active record instrumentation' do
      expect(CanvasStatsd::DefaultTracking).to receive(:instrument_active_record_creation)
      CanvasStatsd::DefaultTracking.send(:track_active_record)
    end
  end

  describe '#subscribe' do
    it 'should subscribe via ActiveSupport::Notifications' do
      target = double()
      CanvasStatsd::DefaultTracking.subscribe(/test.notification/) {|*args| target.callback(*args)}
      expect(target).to receive(:callback)
      ActiveSupport::Notifications.instrument('test.notification') {}
    end
  end

end

