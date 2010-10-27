class CreateShoutChannels < ActiveRecord::Migration
  def self.up
    create_table :shout_channels do |t|
      t.column :company_id,     :integer
      t.column :project_id,     :integer
      t.column :name,           :string
      t.column :description,    :text
      t.column :public,         :integer
    end

    add_column  :shouts, :shout_channel_id,     :integer
    add_column  :shouts, :message_type,         :integer, :default => 0
    add_column  :shouts, :nick,                 :string

    # Create public channels
    chan = ShoutChannel.new
    chan.public = 1
    chan.name = 'General'
    chan.description = 'Public room shared by all ClockingIT users.'
    chan.save

    Company.all.each do |company|
      chan = ShoutChannel.new
      chan.company_id = company.id
      chan.name = company.name
      chan.project_id = nil
      chan.public = 0
      chan.save

      puts "Creating chat channels for [#{company.name}]"

      execute("UPDATE shouts SET shout_channel_id = #{chan.id} WHERE company_id = #{company.id}")

    end

    Shout.all.each do |shout|
      user = shout.user
      n = user.nil? ? ["Anonymous"] : user.name.gsub(/[^\s\w]+/, '').split(" ")
      n = ["Anonymous"] if(n.nil? || n.empty?)
      shout.nick = "#{n[0].capitalize} #{n[1..-1].collect{|e| e[0..0].upcase + "."}.join(' ')}".strip
      shout.save
      puts "[#{shout.id}] Nick[#{shout.nick}]"
    end

    add_index   :shout_channels, :company_id
    add_index   :shouts, :shout_channel_id

  end

  def self.down
    remove_index        :shouts, :shout_channel_id
    remove_index        :shout_channels, :company_id

    remove_column       :shouts, :nick
    remove_column       :shouts, :message_type
    remove_column       :shouts, :shout_channel_id
    drop_table          :shout_channels
  end
end
