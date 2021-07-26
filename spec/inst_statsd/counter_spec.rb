# frozen_string_literal: true

require 'spec_helper'

describe InstStatsd::Counter do

  let(:subject) { InstStatsd::Counter.new('test', ['foo']) }

  describe "#accepted_name?" do
    it 'should return true for names not in blocked_names' do
      expect(subject.accepted_name?('bar')).to eq true
    end

    it 'should return false for names in blocked_names' do
      expect(subject.accepted_name?('foo')).to eq false
    end

    it 'should return true for empty string names' do
      expect(subject.accepted_name?('')).to eq true
    end

    it 'should return true for empty nil names' do
      expect(subject.accepted_name?(nil)).to eq true
    end
  end

  describe "#track" do
    it 'should increment when given allowed names' do
      cookie = subject.start
      subject.track('bar')
      subject.track('baz')
      expect(subject.finalize_count(cookie)).to eq 2
    end

    it 'should not increment when given a blocked name' do
      cookie = subject.start
      subject.track('foo') #shouldn't count as foo is a blocked name
      subject.track('name')
      expect(subject.finalize_count(cookie)).to eq 1
    end
  end

  describe "#finalize_count" do
    it 'should return the current count' do
      cookie = subject.start
      subject.track('bar')
      expect(subject.finalize_count(cookie)).to eq 1
    end

    it 'should not interfere with multiple people using the object' do
      cookie1 = subject.start
      subject.track('bar')
      cookie2 = subject.start
      subject.track('bar')
      expect(subject.finalize_count(cookie1)).to eq 2
      expect(subject.finalize_count(cookie2)).to eq 1
    end
  end

end
