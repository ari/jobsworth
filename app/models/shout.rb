# A chat message in a chat channel

class Shout < ActiveRecord::Base
  belongs_to :shout_channel
  belongs_to :company
  belongs_to :user

  acts_as_ferret({ :fields => { 'company_id' => {},
    'shout_channel_id' => {},
    'body' => { :boost => 1.5 },
    'message_type' => {},
    'nick' => { }
	 }, :remote => true
  })


  def self.full_text_search(q, options = {})
    return nil if q.nil? or q==""
    default_options = {:limit => 20, :page => 1}
    options = default_options.merge options
    options[:offset] = options[:limit] * (options.delete(:page).to_i-1)
    results = WorkLog.find_by_contents(q, options)
    return [results.total_hits, results]
  end

end
