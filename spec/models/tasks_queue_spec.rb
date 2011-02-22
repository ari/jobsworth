require 'spec_helper'

shared_examples_for "task with mimimal sum of weight and weight_adjustment in the company" do
  it "should have mimimal sum of weight and weight_adjustment in the company" do
    min = @company.tasks.minimum("tasks.weight + tasks.weight_adjustment")
    @tasks.should_not be_empty
    @tasks.each{ |task|
      (task.weight + task.weight_adjustment).should == min
    }
  end
end

describe TasksQueue do
  describe "after call to TasksQueue.calculate(company)" do
    before(:each) do
      @company = Company.first || Company.make
      customer= @company.customers.first || Customer.make(:company=> @company)
      user= @company.users.first || User.make(:company=>@company, :customer=>customer)
      Project.make(:company=>@company, :users=>[user], :customer=>customer)


      (20 - @company.tasks.count).times{|i|
        Task.make(:company=>@company, :project=>@company.projects.first, :users=>[user], :weight=>i)
      }

      @company.tasks.limit(5).each_with_index{ |task, i|
        task.hide_until = (i+1).days.from_now
        task.save!
      }

      @company.tasks.limit(5).offset(5).each{ |task|
        task.wait_for_customer= true
        task.save!
      }

      tasks=@company.tasks.limit(5).offset(15)
      @company.tasks.limit(5).offset(10).each_with_index{  |task, i|
        task.dependencies << tasks[i]
        task.save!
      }
      TasksQueue.calculate(@company)
    end

    describe "every task with snooze until date" do
      before(:each) do
        @tasks= @company.tasks.where("tasks.hide_until IS NOT NULL")
      end
      it_should_behave_like "task with mimimal sum of weight and weight_adjustment in the company"
    end

    describe "every task with snooze until customer response" do
      before(:each) do
        @tasks= @company.tasks.where(:wait_for_customer=>true)
      end
      it_should_behave_like "task with mimimal sum of weight and weight_adjustment in the company"
    end

    describe "every task with open dependencies" do
      before(:each) do
        @tasks= @company.tasks.select{ |task| task.dependencies.any?{ |dependency| dependency.open? } }
      end
      it_should_behave_like "task with mimimal sum of weight and weight_adjustment in the company"
    end
  end
end
