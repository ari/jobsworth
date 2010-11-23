require 'test_helper'
require 'rails/performance_test_help'

class TaskFilterTest < ActionDispatch::PerformanceTest
  def setup
    @company = Company.first
    @user= User.first
    @params={"qualifiers_attributes"=>[{"qualifiable_id"=>@company.statuses.first.id, "qualifiable_type"=>"Status", "qualifiable_column"=>"", "reversed"=>"false"}, {"qualifiable_id"=>Project.select(:id).first.id, "qualifiable_type"=>"Project", "reversed"=>"false"}], "keywords_attributes"=>[{"word"=>"key", "reversed"=>"false"}], "unread_only"=>"false"}
    @filter=TaskFilter.make(:company=> @company, :user=> @user)
    @filter.qualifiers.create(:qualifiable=>@company.statuses[1])
    @filter.qualifiers.create(:qualifiable=>@company.customers.first)
    @filter.keywords.create(:word=>"some keyword")
    @filter.save!
    10.times do |i|
      tf=TaskFilter.make(:company=>@company, :user=>@user)
      tf.keywords.create(:word=> "#{i} key")
      tf.store_for(@user)
    end
    assert_equal TaskFilter.recent_for(@user).count, 10
  end

  def test_update_filter_10_times
    #next line works, because running #update_filter twice with same argument cause same result
    10.times{@filter.update_filter(@params)}
  end
  def test_store_for
    10.times{ @filter.store_for(@user) }
  end
end
