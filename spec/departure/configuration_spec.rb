require 'spec_helper'

describe Departure::Configuration do
  describe '#initialize' do
    its(:tmp_path) { is_expected.to eq('.') }
    its(:error_log_filename) { is_expected.to eq('departure_error.log') }
    its(:active) { is_expected.to eql(true) }
  end

  describe '#tmp_path' do
    subject { described_class.new.tmp_path }
    it { is_expected.to eq('.') }
  end

  describe '#tmp_path=' do
    subject { described_class.new.tmp_path = '/tmp' }
    it { is_expected.to eq('/tmp') }
  end

  describe '#active?' do
    subject { described_class.new.active? }
    it { is_expected.to eql(true) }
  end

  describe '#active=' do
    subject { described_class.new.active = false }
    it { is_expected.to eql(false) }
  end
end
