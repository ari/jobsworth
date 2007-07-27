jabber = Jabber::Simple.new('rex@friendosaurus.com', 'password')
jabber.deliver("bront@friendosaurus.com", "Hey! I'm thinking of going Vegetarian - Any suggestions?")

jabber.add("friend@example.com")
jabber.remove("unfriendly@example.com")


jabber.received_messages do |msg|
  puts "#{msg.body}" if msg.type == :chat
end


jabber.status(:away, "Eating at the Tree Cafe. I need a ladder.")

jabber.presence_updates do |update|
    from     = update[0].jid.strip.to_s
    status   = update[2].status
    presence = update[2].show
    puts "#{from} went #{presence}: #{status}"
end

# sudo gem install xmpp4r-simple

