xm.item do
  key = post.topic.posts_count == 1 ? :topic_posted_by : :topic_replied_by
  xm.title "{title} posted by {user} @ {date}"[key, h(post.respond_to?(:topic_title) ? post.topic_title : post.topic.title), h(post.user.login), post.created_at.rfc822]
  xm.description post.body_html
  xm.pubDate post.created_at.rfc822
  xm.guid [request.host_with_port+request.relative_url_root, post.forum_id.to_s, post.topic_id.to_s, post.id.to_s].join(":"), "isPermaLink" => "false"
  xm.author "#{post.user.login}"
  xm.link topic_url(post.forum_id, post.topic_id)
end
