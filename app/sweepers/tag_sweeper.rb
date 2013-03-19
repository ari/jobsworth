# encoding: UTF-8
class TagSweeper < ActionController::Caching::Sweeper
  include CacheHelper

  observe Tag
  def after_save(record)
    reset_group_cache! "tags/company_#{record.company_id}/"
  end
  def after_destroy(record)
    reset_group_cache! "tags/company_#{record.company_id}/"
  end
end

