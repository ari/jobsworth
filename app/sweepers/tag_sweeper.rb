class TagSweeper < ActionController::Caching::Sweeper
  observe Tag
  def after_save(record)
    expire_matched_fragment_in_dir("/views/tags/#{record.company_id}/",%r{.*})
  end
  def after_destroy(record)
    expire_matched_fragment_in_dir("/views/tags/#{record.company_id}/",%r{.*})
  end
end

