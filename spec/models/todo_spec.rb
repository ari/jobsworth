require 'spec_helper'

describe Todo do

  it { is_expected.to belong_to :task }
  it { is_expected.to belong_to :completed_by_user }

  describe '#done?' do
    subject { described_class.new({completed_at: completed_at}) }

    context 'when completed_at is nil' do
      let(:completed_at) { nil }
      it { expect(subject.done?).to be_falsey }
    end

    context 'when completed_at is a date' do
      let(:completed_at) { Time.now }
      it { expect(subject.done?).to be_truthy }
    end
  end

  describe '#css_classes' do
    skip 'This method should be in a helper/decorator!'
  end

end
