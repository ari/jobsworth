# Virtual table, doesn't exist in the database
#
# Generated chat transcripts, based on the chats done

class Transcript < ActiveRecord::BaseWithoutTable

  belongs_to :user
  belongs_to :shout_channel

  def self.find_all(company_id, channel_ids)
    # MySQL
    find_by_sql(["SELECT DISTINCT shout_channel_id, user_id, DAY(created_at) as day,MONTH(created_at) as month, YEAR(created_at) as year FROM shouts WHERE shout_channel_id IN (?) AND (company_id IS NULL OR company_id = ?) AND message_type = 0 ORDER BY created_at desc", channel_ids, company_id])
    # PostgreSQL
    #find_by_sql(["SELECT DISTINCT shout_channel_id, user_id, date_part('day',created_at) as day, date_part('month',created_at) as month, date_part('year',created_at) as year FROM shouts WHERE shout_channel_id IN (?) AND (company_id IS NULL OR company_id = ?) AND message_type = 0 ORDER BY created_at desc", channel_ids, company_id])
  end
end
