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

  test "group cache entries should not change on multiple calls but should change after a reset" do
    proc = -> { [grouped_cache_key("g", 1), grouped_cache_key("g", 2)] }
    
    keys1 = proc.call
    keys2 = proc.call
    assert_equal keys1, keys2

    reset_group_cache! "g"
    keys2 = proc.call
    assert_equal 0, (keys1 & keys2).size
  end

  test "group_cache_key matches the expected format" do
    key = grouped_cache_key "group/key/prefix", "sub/key"
    assert_match /^group\/key\/prefix\/[0-9]{,8}\/sub\/key/, key, "#{key.inspect} doesn't match expected regex"
  end

  test "group_cache_index should be always same without reset" do
    indices = 10.times.map { group_cache_index("example") }
    assert_equal 1, indices.uniq.size
  end

  test "group_cache_index should be different after each reset" do
    indices = 10.times.map { reset_group_cache!("example"); group_cache_index("example") }
    assert_equal 10, indices.uniq.size
  end

end
