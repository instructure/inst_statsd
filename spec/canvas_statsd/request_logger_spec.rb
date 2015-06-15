require 'spec_helper'
require 'logger'

describe CanvasStatsd::RequestLogger do

  describe '#build_log_message' do
    before :all do
      @logger = CanvasStatsd::RequestLogger.new(Logger.new(STDOUT))
    end
    it 'should include the supplied header' do
      request_stat = double('request_stat')
      results = @logger.build_log_message(request_stat, 'FOO_STATS')
      expect(results).to eq("[FOO_STATS]")
    end
    it 'should fallback to the default header' do
      request_stat = double('request_stat')
      results = @logger.build_log_message(request_stat)
      expect(results).to eq("[STATSD]")
    end
    it 'should include stats that are available' do
      request_stat = double('request_stat')
      request_stat.stub(:ms).and_return(100.2)
      request_stat.stub(:ar_count).and_return(24)
      results = @logger.build_log_message(request_stat)
      expect(results).to eq("[STATSD] (total: 100.2) (active_record: 24)")
    end
    it 'should not include nil stats' do
      request_stat = double('request_stat')
      request_stat.stub(:ms).and_return(100.2)
      request_stat.stub(:ar_count).and_return(nil)
      results = @logger.build_log_message(request_stat)
      expect(results).to eq("[STATSD] (total: 100.2)")
    end
  end

  describe '#log' do
    it 'should send info method to logger if logger exists' do
      std_out_logger = Logger.new(STDOUT)
      logger = CanvasStatsd::RequestLogger.new(std_out_logger)
      expect(std_out_logger).to receive(:info)
      request_stat = double('request_stat')
      logger.log(request_stat)
    end
    it 'should send info method with build_log_message output if logger exists' do
      std_out_logger = Logger.new(STDOUT)
      logger = CanvasStatsd::RequestLogger.new(std_out_logger)
      expect(std_out_logger).to receive(:info).with("[DEFAULT_METRICS] (total: 100.2)")
      request_stat = double('request_stat')
      request_stat.stub(:ms).and_return(100.2)
      logger.log(request_stat, "DEFAULT_METRICS")
    end
  end

end
