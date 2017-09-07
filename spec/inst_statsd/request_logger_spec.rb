require 'spec_helper'
require 'logger'

describe InstStatsd::RequestLogger do

  describe '#build_log_message' do
    before :all do
      @logger = InstStatsd::RequestLogger.new(Logger.new(STDOUT))
    end
    it 'includes the supplied header' do
      request_stat = double('request_stat')
      allow(request_stat).to receive(:exclusive_stats).and_return(nil)
      allow(request_stat).to receive(:stats).and_return({})
      results = @logger.build_log_message(request_stat, 'FOO_STATS')
      expect(results).to eq("[FOO_STATS]")
    end
    it 'falls back to the default header' do
      request_stat = double('request_stat')
      allow(request_stat).to receive(:exclusive_stats).and_return(nil)
      allow(request_stat).to receive(:stats).and_return({})
      results = @logger.build_log_message(request_stat)
      expect(results).to eq("[STATSD]")
    end
    it 'includes stats that are available' do
      request_stat = double('request_stat')
      allow(request_stat).to receive(:exclusive_stats).and_return(nil)
      allow(request_stat).to receive(:stats).and_return(
          "total" => 100.21,
          "active.record" => 24)
      results = @logger.build_log_message(request_stat)
      expect(results).to eq("[STATSD] (total: 100.21) (active_record: 24.00)")
    end

    it 'includes exclusive_stats if there are any' do
      request_stat = double('request_stat')
      allow(request_stat).to receive(:stats).and_return(
          "total" => 100.21,
          "active.record" => 24)
      allow(request_stat).to receive(:exclusive_stats).and_return(
          "total" => 54.32,
          "active.record" => 1)
      results = @logger.build_log_message(request_stat)
      expect(results).to eq("[STATSD] (total: 100.21) (active_record: 24.00) (exclusive_total: 54.32) (exclusive_active_record: 1.00)")
    end

    describe 'decimal precision' do
      it 'forces 2 decimal precision' do
        request_stat = double('request_stat')
        allow(request_stat).to receive(:stats).and_return(total: 72.1)
        allow(request_stat).to receive(:exclusive_stats).and_return(nil)
        results = @logger.build_log_message(request_stat)
        expect(results).to eq("[STATSD] (total: 72.10)")
      end
      it 'rounds values to 2 decimals' do
        request_stat = double('request_stat')
        allow(request_stat).to receive(:stats).and_return(total: 72.1382928)
        allow(request_stat).to receive(:exclusive_stats).and_return(nil)
        results = @logger.build_log_message(request_stat)
        expect(results).to eq("[STATSD] (total: 72.14)")
        allow(request_stat).to receive(:stats).and_return(total: 72.1348209)
        results = @logger.build_log_message(request_stat)
        expect(results).to eq("[STATSD] (total: 72.13)")
      end
    end

  end

  describe '#log' do
    it 'sends info method to logger if logger exists' do
      std_out_logger = Logger.new(STDOUT)
      logger = InstStatsd::RequestLogger.new(std_out_logger)
      expect(std_out_logger).to receive(:info)
      request_stat = double('request_stat')
      allow(request_stat).to receive(:stats).and_return({})
      allow(request_stat).to receive(:exclusive_stats).and_return(nil)
      logger.log(request_stat)
    end
    it 'sends info method with build_log_message output if logger exists' do
      std_out_logger = Logger.new(STDOUT)
      logger = InstStatsd::RequestLogger.new(std_out_logger)
      expect(std_out_logger).to receive(:info).with("[DEFAULT_METRICS] (total: 100.20)")
      request_stat = double('request_stat')
      allow(request_stat).to receive(:stats).and_return(total: 100.2)
      allow(request_stat).to receive(:exclusive_stats).and_return(nil)
      logger.log(request_stat, "DEFAULT_METRICS")
    end
  end

end
