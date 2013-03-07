require 'spec_helper'

describe TaskRecord do

  describe '#user_work' do
    subject { TaskRecord.new }
    let(:user1) { stub :user1 }
    let(:user2) { stub :user2 }

    let(:user_duration1) { stub _user_: user1, duration: 1000 }
    let(:user_duration2) { stub _user_: user2, duration: 500 }

    before { subject.stub_chain('work_logs.duration_per_user' => [user_duration1, user_duration2]) }

    its(:user_work) { should == {user1 => 1000, user2 => 500} }
  end

end
