# encoding: UTF-8
class TagSweeper < ActionController::Caching::Sweeper
  observe Tag
  def after_save(record)
    expire_fragment(%r{tags\/#{record.company_id}\/*})
  end
  def after_destroy(record)
    expire_fragment(%r{tags\/#{record.company_id}\/*})
  end
end

