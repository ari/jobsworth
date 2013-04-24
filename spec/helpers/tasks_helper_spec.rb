require 'spec_helper'

describe TasksHelper do

  describe '#cloud_ranges' do
    it 'should return an array of numbers' do
      expect(helper.cloud_ranges(1..20)).to eql [0, 4, 8, 12, 16]
    end
  end

  describe '#human_future_date' do
    before { Timecop.freeze Time.utc 1986, 3, 23, 10, 0 }
    after  { Timecop.return }

    let(:date) { Time.now }
    let(:tz)   { TZInfo::Timezone.get('Europe/Budapest') }
    subject { helper.human_future_date date, tz }

    context 'date is nil' do
      let(:date) { nil }
      it { expect(subject).to eql 'Unknown' }
    end

    context 'date is a year ago' do
      let(:date) { 12.months.ago - 1.second }
      it { expect(subject).to eql '<time datetime="1985-03-23T09:59:59Z" title="1985-03-23"><span class="label">1985</span></time>' }
    end

    context 'date is 30 days ago' do
      let(:date) { 30.days.ago - 1.second }
      it { expect(subject).to eql '<time datetime="1986-02-21T09:59:59Z" title="1986-02-21"><span class="label">Feb</span></time>' }
    end

    context 'date is 7 days ago' do
      let(:date) { 7.days.ago - 1.second }
      it { expect(subject).to eql '<time datetime="1986-03-16T09:59:59Z" title="1986-03-16"><span class="label">-8 days</span></time>' }
    end

    context 'date is 2 days ago' do
      let(:date) { 2.days.ago - 1.second }
      it { expect(subject).to eql '<time datetime="1986-03-21T09:59:59Z" title="1986-03-21"><span class="label">last Fri</span></time>' }
    end

    context 'date is yesterday' do
      let(:date) { 1.day.ago - 1.second }
      it { expect(subject).to eql '<time datetime="1986-03-22T09:59:59Z" title="1986-03-22"><span class="label label-info">yesterday</span></time>' }
    end

    context 'date is today' do
      let(:date) { 1.second.ago }
      it { expect(subject).to eql '<time datetime="1986-03-23T09:59:59Z" title="1986-03-23"><span class="label label-warning">today</span></time>' }
    end

    context 'date is tomorrow' do
      let(:date) { 1.day.from_now }
      it { expect(subject).to eql '<time datetime="1986-03-24T10:00:00Z" title="1986-03-24"><span class="label label-info">tomorrow</span></time>' }
    end

    context 'date is 7 days from now' do
      let(:date) { 7.day.from_now }
      it { expect(subject).to eql '<time datetime="1986-03-30T10:00:00Z" title="1986-03-30"><span class="label">Sun</span></time>' }
    end

    context 'date is 30 days from now' do
      let(:date) { 30.day.from_now }
      it { expect(subject).to eql '<time datetime="1986-04-22T10:00:00Z" title="1986-04-22"><span class="label">30 days</span></time>' }
    end

    context 'date is a year from now' do
      let(:date) { 12.months.from_now }
      it { expect(subject).to eql '<time datetime="1987-03-23T10:00:00Z" title="1987-03-23"><span class="label">Mar</span></time>' }
    end

    context 'date is more then year from now' do
      let(:date) { 12.months.from_now + 1.day }
      it { expect(subject).to eql '<time datetime="1987-03-24T10:00:00Z" title="1987-03-24"><span class="label">1987</span></time>' }
    end
  end


end
