require File.dirname(__FILE__) + '/../test_helper'
require 'notifications'

class NotificationsTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_created
    @expected.subject = 'Notifications#created'
    @expected.body    = read_fixture('created')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifications.create_created(@expected.date).encoded
  end

  def test_changed
    @expected.subject = 'Notifications#changed'
    @expected.body    = read_fixture('changed')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifications.create_changed(@expected.date).encoded
  end

  def test_commented
    @expected.subject = 'Notifications#commented'
    @expected.body    = read_fixture('commented')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifications.create_commented(@expected.date).encoded
  end

  def test_completed
    @expected.subject = 'Notifications#completed'
    @expected.body    = read_fixture('completed')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifications.create_completed(@expected.date).encoded
  end

  def test_assigned
    @expected.subject = 'Notifications#assigned'
    @expected.body    = read_fixture('assigned')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifications.create_assigned(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/notifications/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
