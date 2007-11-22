class Transcript < ActiveRecord::BaseWithoutTable

  belongs_to :user
  belongs_to :shout_channel

  def self.find_all(company_id)
    find_by_sql(["SELECT DISTINCT shout_channel_id, user_id, DAY(created_at) as day,MONTH(created_at) as month, YEAR(created_at) as year FROM shouts WHERE (company_id IS NULL OR company_id = ?) ORDER BY created_at desc", company_id])
  end
end
