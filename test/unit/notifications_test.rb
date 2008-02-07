require File.dirname(__FILE__) + '/../test_helper'
require 'notifications'

class NotificationsTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"
  fixtures :users, :tasks, :projects, :customers, :companies

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_created
    @expected.subject = '[ClockingIT] Created: [#1] Test (Unassigned)'
    @expected.from    = 'admin@clockingit.com'
    @expected['Reply-To'] = 'task-1@cit.clockingit.com'
    @expected.to      = 'admin@clockingit.com'
    @expected['Mime-Version'] = '1.0'
    @expected.body    = read_fixture('created')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifications.create_created(Task.find(1), User.find(1), "", @expected.date).encoded
  end

  def test_changed
    @expected.subject = '[ClockingIT] Resolved: [#1] Test -> Open (Erlend Simonsen)'
    @expected.from    = 'admin@clockingit.com'
    @expected['Reply-To'] = 'task-1@cit.clockingit.com'
    @expected.to      = 'admin@clockingit.com'
    @expected['Mime-Version'] = '1.0'
    @expected.body    = read_fixture('changed')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifications.create_changed(:completed, Task.find(1), User.find(1), "Task Changed", @expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/notifications/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
