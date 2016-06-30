require 'spec_helper'

describe TaskFilter do
  before(:each) do
    @valid_attributes = {

    }
  end

  describe '.recent_for(user) scope' do
    it 'should return recent task filters for user' do
      user=User.make
      filters=[]
      4.times { filters<< TaskFilter.make(:user => user, :recent_for_user_id => user.id, :company => user.company) }
      4.times { TaskFilter.make(:user => user, :company => user.company) }
      expect(TaskFilter.recent_for(user)).to eq(filters.reverse)
    end
  end

  describe '#store_for(user)' do
    before(:each) do
      @user= User.make
      @filter = TaskFilter.make(:user => @user, :company => @user.company)
      @filter.qualifiers << [TaskFilterQualifier.new(:qualifiable => Project.make(:company => @user.company)),
                             TaskFilterQualifier.new(:qualifiable => @user.company.statuses.first),
                             TaskFilterQualifier.new(:qualifiable => @user)
      ]
      @filter.keywords << Keyword.new(:word => 'keyword')
      @filter.save!
      expect(@filter.qualifiers.count).to eq(3)
    end
    it 'should create new task filter' do
      count= TaskFilter.count
      @filter.store_for(@user)
      expect(TaskFilter.count).to eq(count + 1)
    end
    it "should delete last recent user's filter if user have 10 recent filters" do
      arr=[]
      10.times { arr<< TaskFilter.make(:user => @user, :company => @user.company); arr[-1].store_for(@user) }
      expect(TaskFilter.recent_for(@user).count).to eq(10)
      @filter.store_for(@user)
      expect(TaskFilter.recent_for(@user).count).to eq(10)
      expect(TaskFilter.recent_for(@user).last.name).to eq(arr[1].name)
    end

    it "should include all items(qualifiers or keywords) in filter's name" do
      @filter.store_for(@user)
      expect(TaskFilter.recent_for(@user).first.name.split(',').size).to eq(@filter.qualifiers.size + @filter.keywords.size)
    end
  end
end


# == Schema Information
#
# Table name: task_filters
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  company_id         :integer(4)
#  user_id            :integer(4)
#  shared             :boolean(1)
#  created_at         :datetime
#  updated_at         :datetime
#  system             :boolean(1)      default(FALSE)
#  unread_only        :boolean(1)      default(FALSE)
#  recent_for_user_id :integer(4)
#
# Indexes
#
#  fk_task_filters_company_id  (company_id)
#  fk_task_filters_user_id     (user_id)
#

