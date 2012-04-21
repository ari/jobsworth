require "test_helper"

class TaskTest < ActiveRecord::TestCase
  fixtures :tasks, :projects, :users, :companies, :customers, :properties, :property_values

  should have_many(:task_customers).dependent(:destroy)
  should have_many(:customers).through(:task_customers)

  def setup
    @task = tasks(:normal_task)
  end
  subject { @task }

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Task,  @task
  end

  def test_done?
    task = Task.new
    task.status = 0
    task.completed_at = nil
    assert_not_equal true, task.done?

    task.status = 2
    assert_not_equal true, task.done?

    task.status = 1
    assert_not_equal true, task.done?

    task.status = 0
    task.completed_at = Time.now.utc
    assert_not_equal true, task.done?

    task.status = 2
    task.completed_at = Time.now.utc
    assert_equal true, task.done?
  end

  def test_after_save
    # TODO
  end

  def test_ready?
    # TODO
  end

  def test_active?
    @task.hide_until = nil
    assert @task.active?

    @task.hide_until = Time.now.utc - 1.hour
    assert @task.active?

    @task.hide_until = Time.now.utc + 1.hour
    assert !@task.active?
  end

  def test_worked_on?
     assert !@task.worked_on?

     sheet = @task.sheets.build(:project => projects(:test_project), :user => users(:admin) )
     sheet.save

     assert @task.worked_on?
  end

  def test_set_task_num
    max = Task.where("company_id = ?", @task.company.id).maximum('task_num')
    task = @task.dup
    task.save
    assert_equal max + 1, task.task_num
  end

  def test_overdue?
    @task.due_at = nil
    assert_equal false, @task.overdue?

    @task.due_at = Time.now.utc + 1.day
    assert_equal false, @task.overdue?

    @task.due_at = Time.now.utc - 1.day
    assert_equal true, @task.overdue?
  end

  def test_worked_minutes
    # TODO
  end

  def test_full_name
    # TODO
  end

  def test_full_tags
    # TODO
  end

  def test_full_name_without_links
    # TODO
  end

  def test_full_tags_without_links
    # TODO
  end

  def test_issue_name
    assert_equal "[#1] Test", @task.issue_name
  end

  def test_issue_num
    assert_equal "#1", @task.issue_num

    @task.status = 2
    assert_equal "<strike>#1</strike>", @task.issue_num
  end

  def test_status_name
    assert_equal "#1 Test", @task.status_name

    @task.status = 2
    assert_equal "<strike>#1</strike> Test", @task.status_name
  end

  def test_properties_setter
    prop = properties(:first)
    v1 = property_values(:first)
    v2 = property_values(:third)

    @task.properties = {
      properties(:first).id => v1.id,
      properties(:second).id => v2.id
    }
    @task.save!
    @task.task_property_values.reload

    tpv = @task.task_property_values.detect { |tpv| tpv.property_id == properties(:first).id }
    assert_equal v1, tpv.property_value
    tpv = @task.task_property_values.detect { |tpv| tpv.property_id == properties(:second).id }
    assert_equal v2, tpv.property_value
  end

  def test_properties_setter_should_clear_old_properties
    prop = properties(:first)
    v1 = property_values(:first)
    v2 = property_values(:third)

    @task.properties = {
      properties(:first).id => v1.id,
      properties(:second).id => v2.id
    }
    @task.save!
    assert_equal 2, @task.task_property_values.reload.length

    @task.properties = { properties(:first).id => v1.id }
    @task.save!
    assert_equal 1, @task.task_property_values.reload.length
  end

  def test_set_property_value_should_clear_value_if_nil
    prop = properties(:first)
    v1 = property_values(:first)

    @task.set_property_value(prop, v1)
    assert_equal v1, @task.property_value(prop)
    @task.set_property_value(prop, nil)
    assert_equal(nil, @task.property_value(prop))
  end

  def test_property_value
    v1 = property_values(:first)
    @task.task_property_values.create(:property_id => v1.property_id, :property_value_id => v1.id)
    v2 = property_values(:third)
    @task.task_property_values.create(:property_id => v2.property_id, :property_value_id => v2.id)

    assert_equal v1, @task.property_value(v1.property)
    assert_equal v2, @task.property_value(v2.property)
  end

  def test_users_to_notify_returns_watchers_and_users
    u1 = users(:admin)
    u2 = users(:fudge)

    @task.watchers << u1
    @task.owners << u2

    users = @task.users_to_notify
    assert users.include?(u1)
    assert users.include?(u2)
  end

  def test_users_to_notify_does_not_return_people_who_dont_want_notifications
    u1 = users(:admin)
    u1.receive_notifications = false
    u1.save
    u2 = users(:fudge)

    @task.watchers << u1
    @task.owners << u2

    users = @task.users_to_notify
    assert !users.include?(u1)
    assert users.include?(u2)
  end

  def test_users_to_notify_respects_receive_own_notifications
    u1 = users(:admin)
    u1.receive_own_notifications = false
    u2 = users(:fudge)

    @task.watchers << u1
    @task.owners << u2

    users = @task.users_to_notify(u1)
    assert !users.include?(u1)
    assert users.include?(u2)

    u1.receive_own_notifications = true
    users = @task.users_to_notify(u1)
    assert users.include?(u1)
  end

  def test_users_to_notify_respects_active_users
    u1 = users(:admin)
    u1.receive_own_notifications = true
    u2 = users(:fudge)

    @task.watchers << u1
    @task.owners << u2
    users = @task.users_to_notify(u1)
    assert users.include?(u2)
    assert users.include?(u1)

    u2.active = false
    u2.save!
    users = @task.users_to_notify(u1)
    assert !users.include?(u2)
  end

  def test_mark_as_unread
    u1 = users(:admin)
    u1.receive_own_notifications = false
    u2 = users(:fudge)

    @task.watchers << u1
    @task.owners << u2

    @task.mark_as_unread

    n = @task.task_watchers.where(:user_id => u1.id).first
    assert_not_nil n
    assert n.unread?

    o = @task.task_owners.where(:user_id => u2.id).first
    assert_not_nil n
    assert o.unread?
  end

  def test_unread?
    u1 = users(:admin)
    u1.receive_own_notifications = false
    u2 = users(:fudge)

    @task.watchers << u1
    @task.owners << u2

    n = @task.task_watchers.where(:user_id => u1.id).first
    n.unread = true
    n.save

    assert n.unread?
    assert @task.unread?(u1)
  end

  def test_validate_checks_mandatory_properties
    property = @task.company.properties.first
    property.update_attribute(:mandatory, true)

    @task.task_property_values.clear
    assert !@task.valid?
    assert @task.errors.any?

    @task.set_property_value(property, property.property_values.first)
    assert @task.valid?

    property.update_attribute(:mandatory, false)
    @task.company.properties.reload
    @task.task_property_values.clear
    assert @task.valid?
  end

  context "a normal task" do
    setup do
      @task = Task.first
    end

    should "accept nested attributes for todos" do
      assert @task.respond_to?("todos_attributes=")
    end

    should "add and remove task customers using customer_attributes=" do
      c1 = @task.company.customers.first
      c2 = @task.company.customers.last
      assert_not_equal c1, c2

      assert_equal 0, @task.customers.length
      @task.customer_attributes = {
        c1.id => { "member" => "1" },
        c2.id => { "member" => "1" }
      }
      assert_equal 2, @task.customers.length

      @task.customer_attributes = {
        c1.id => { "add" => "1" }
      }
      assert_equal 1, @task.customers.length
      assert_equal c1, @task.task_customers.first.customer
    end
    context "with status 0" do
      setup do
        @task.status=0
        @task.save!
      end
      should "have status type 'Open'" do
        assert_equal "Open", @task.status_type
      end
      should "not be resolved" do
        assert !@task.resolved?
      end
      should "be open" do
        assert @task.open?
      end
    end
    context "with status 1" do
      setup do
        @task.status=1
        @task.save!
      end
      should "have status type 'Closed'" do
        assert_equal "Closed", @task.status_type
      end
      should "be resolved" do
        assert @task.resolved?
      end
      should "be closed" do
        assert @task.closed?
      end
    end
    context "with status 2" do
      setup do
        @task.status=2
        @task.save!
      end
      should "have status type 'Won't fix'" do
        assert_equal "Won't fix", @task.status_type
      end
      should "be resolved" do
        assert @task.resolved?
      end
      should "be will not fix" do
        assert @task.will_not_fix?
      end
    end
    context "with status 3" do
      setup do
        @task.status=3
        @task.save!
      end
      should "have status type 'Invalid'" do
        assert_equal "Invalid", @task.status_type
      end
      should "be resolved" do
        assert @task.resolved?
      end
      should "be invalid" do
        assert @task.invalid?
      end
    end
    context "with status 4" do
      setup do
        @task.status=4
        @task.save!
      end
      should "have status type 'Duplicate'" do
        assert_equal "Duplicate", @task.status_type
      end
      should "be resolved" do
        assert @task.resolved?
      end
      should "be duplicate" do
        assert @task.duplicate?
      end
    end

  end

  context "a task with some work logs with times" do
    setup do
      @task = Task.first
      @user1 = User.make
      @user2 = User.make
      @user3 = User.make

      @task.work_logs.make(:user => @user1, :duration => 50)
      @task.work_logs.make(:user => @user1, :duration => 100)
      @task.work_logs.make(:user => @user2, :duration => 77)
      @task.work_logs.make(:user => @user3, :duration => 0)
    end

    should "return duration work grouped by users" do
      work = @task.user_work
      assert_equal 150, work[@user1]
      assert_equal 77, work[@user2]
      assert_nil work[@user3]
    end
  end
  context "Task.expire_hide_until" do
    setup do
      @future_task = Task.make(:hide_until=>@date=3.days.from_now)
      @past_task   = Task.make(:hide_until=>Time.now - 3.days)
    end
    should "set hide_until to nil if hide_until date is passed" do
      Task.expire_hide_until
      assert_equal @future_task.reload.hide_until.to_date, @date.to_date
      assert_nil   @past_task.reload.hide_until
    end
  end
end













# == Schema Information
#
# Table name: tasks
#
#  id                 :integer(4)      not null, primary key
#  name               :string(200)     default(""), not null
#  project_id         :integer(4)      default(0), not null
#  position           :integer(4)      default(0), not null
#  created_at         :datetime        not null
#  due_at             :datetime
#  updated_at         :datetime        not null
#  completed_at       :datetime
#  duration           :integer(4)      default(1)
#  hidden             :integer(4)      default(0)
#  milestone_id       :integer(4)
#  description        :text
#  company_id         :integer(4)
#  priority           :integer(4)      default(0)
#  updated_by_id      :integer(4)
#  severity_id        :integer(4)      default(0)
#  type_id            :integer(4)      default(0)
#  task_num           :integer(4)      default(0)
#  status             :integer(4)      default(0)
#  creator_id         :integer(4)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#  weight             :integer(4)      default(0)
#  weight_adjustment  :integer(4)      default(0)
#  wait_for_customer  :boolean(1)      default(FALSE)
#  estimate           :decimal(5, 2)
#
# Indexes
#
#  index_tasks_on_type_and_task_num_and_company_id  (type,task_num,company_id) UNIQUE
#  tasks_company_id_index                           (company_id)
#  tasks_due_at_idx                                 (due_at)
#  index_tasks_on_milestone_id                      (milestone_id)
#  tasks_project_completed_index                    (project_id,completed_at)
#  tasks_project_id_index                           (project_id,milestone_id)
#

