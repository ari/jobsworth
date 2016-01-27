require 'test_helper'

class CacheHelperTest < ActionView::TestCase
  setup do
    @prev_cache_config = Rails.application.config.action_controller.perform_caching
    @prev_cache_store  = Rails.application.config.cache_store

    Rails.application.config.action_controller.perform_caching = true
    # Rails still seems to create files in tmp/cache
    Rails.application.config.cache_store = :memory_store
  end

  teardown do
    Rails.application.config.action_controller.perform_caching = @prev_cache_config
    Rails.application.config.cache_store = @prev_cache_store
  end

  test "group_cache_key matches the expected format" do
    key = grouped_cache_key "group/key/prefix", "sub/key"
    assert_match /^group\/key\/prefix\/[0-9]{,8}\/sub\/key/, key, "#{key.inspect} doesn't match expected regex"
  end

  test "grouped_cache_key should always be same without reset" do
    keys = 10.times.map { grouped_cache_key("example", "sub") }
    assert_equal 1, keys.uniq.size
  end

  test "grouped_cache_key should be different after each reset" do
    keys = 10.times.map { reset_group_cache!("example"); grouped_cache_key("example", "sub") }
    assert_equal 10, keys.uniq.size
  end

end
