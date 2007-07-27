module ForumsHelper

  # used to know if a topic has changed since we read it last
  def recent_topic_activity(topic)
    return topic.replied_at > (session[:topics][topic.id] || last_active) if session[:topics]
  end

  # used to know if a forum has changed since we read it last
  def recent_forum_activity(forum)
    return false unless forum.topics.first
    return forum.recent_topics.first.replied_at > (session[:forums][forum.id] || last_active) if session[:forums]
  end

end
