# frozen_string_literal: true

require 'spec_helper'

module InstStatsd
  describe SqlTracker do

    describe '#start' do
      it 'resets values to zero' do
        subject = SqlTracker.new
        subject.start
        subject.track 'CACHE', 'SELECT * FROM some_table'
        cookies = subject.start
        expect(subject.finalize_counts(cookies)).to eq([0, 0, 0])
      end
    end

    describe '#track' do
      before :each do
        @subject = SqlTracker.new
        @cookies = @subject.start
      end

      def finish
        if @num_reads.nil?
          @num_reads, @num_writes, @num_caches = @subject.finalize_counts(@cookies)
        end
      end

      def num_reads
        finish
        @num_reads
      end

      def num_writes
        finish
        @num_writes
      end

      def num_caches
        finish
        @num_caches
      end

      it 'considers CACHE above all' do
        @subject.track 'CACHE', 'SELECT * FROM some_table'
        expect(num_caches).to eq(1)
        expect(num_reads).to eq(0)
      end

      it 'marks as read when select is in the first 15 chars of the sql' do
        @subject.track 'LOAD', '  SELECT "context_external_tools".* FROM'
        expect(num_reads).to eq(1)
        expect(num_writes).to eq(0)
      end

      it 'marks as read with no select, but a LOAD name' do
        @subject.track 'LOAD', 'WITH RECURSIVE t AS'
        expect(num_reads).to eq(1)
        expect(num_writes).to eq(0)
      end

      it 'doesnt track names set as blocked' do
        tracker = SqlTracker.new(blocked_names: ['SCHEMA'])
        cookies = tracker.start
        tracker.track 'SCHEMA', 'SELECT * FROM some_table'
        expect(tracker.finalize_counts(cookies)[0]).to eq(0)
      end

      it 'doesnt track nil names or sql values' do
        @subject.track nil, 'SELECT *'
        @subject.track 'CACHE', nil
        expect(num_reads).to eq(0)
      end

      it 'passes full sql to counter.track calls for reads' do
        sql = '  SELECT \'context_external_tools\'.* FROM'
        read_counter = double()
        allow(read_counter).to receive(:start)
        expect(read_counter).to receive(:track).with sql
        tracker = SqlTracker.new(read_counter: read_counter)
        tracker.start
        tracker.track 'LOAD', sql
      end

      it 'passes full sql to counter.track calls for writes' do
        sql = '  UPDATE \'context_external_tools\'.* FROM'
        write_counter = double()
        allow(write_counter).to receive(:start)
        expect(write_counter).to receive(:track).with sql
        tracker = SqlTracker.new(write_counter: write_counter)
        tracker.start
        tracker.track 'UPDATE', sql
      end
    end

  end
end
