# Using expire_fragment with a regular expression is PITA as it makes Rails iterate over all the cache keys which is too slow.
# Additionally, some cache strategies don't support iterating over keys, making it non-trivial to drop multiple cache entries.
#
# This helper makes it possible to group together multiple cache entries, making it easier to drop all grouped cache entries together.
# It works by assigning a prefix to all cache entries in a group. To delete all the cache entries of a group, 
# it simply renames the prefix for that group, making all cache entries to be re-generated on request, while old entries are 
# garbage collected by the backend cache store.
#
# Original idea from http://quickleft.com/blog/faking-regex-based-cache-keys-in-rails
module CacheHelper
  CACHE_KEY_PREFIX = "group_cache_index_for"

  def grouped_cache_key group_key, sub_key
    "#{group_key}/#{group_cache_index(group_key)}/#{sub_key}"
  end

  def reset_group_cache! group_key
    Rails.cache.delete("#{CACHE_KEY_PREFIX}/#{group_key}")
  end

private

  def group_cache_index group_key
    Rails.cache.fetch("#{CACHE_KEY_PREFIX}/#{group_key}") { rand(10**8).to_s }
  end
  
end
