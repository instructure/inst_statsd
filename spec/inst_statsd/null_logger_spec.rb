# frozen_string_literal: true

require 'spec_helper'

describe InstStatsd::NullLogger do

  describe 'initialize' do
    it 'takes any arguments' do
      expect{InstStatsd::NullLogger.new}.to_not raise_error
      expect{InstStatsd::NullLogger.new(1, 2, 3)}.to_not raise_error
    end
  end

  describe 'debug, info, warn, fatal, and unknown' do
    it 'should all no-op instead of logging' do
      log_path = 'spec/support/test.log'
      File.open(log_path, 'w') { |f| f.write('') } # empty log file
      logger = InstStatsd::NullLogger.new(log_path)
      %w[debug info warn error fatal unknown].each { |m| logger.send(m, 'foo') }
      log_contents = File.read(log_path)
      expect(log_contents).to eq ''
    end
  end

end
