class CopyAvatarsAndLogos < ActiveRecord::Migration
  def self.up
    Customer.all.each{ |customer|
      logo_path= File.join(RAILS_ROOT, 'store', 'logos', customer.company_id.to_s, "logo_#{customer.id}")
      if File.exist?(logo_path)
        begin
          customer.logo = File.new(logo_path)
          customer.save!
        rescue Exception => e
          str= "\nCall to parerclip raise an exception\n"
          str<< "Customer object inspect:\n"
          str<< customer.inspect
          str<< "\nFile: #{logo_path}\n"
          str<< "Paperclip.options hash:\n"
          str<< Paperclip.options.inspect
          p e.message + str
        end
      end
    }
    User.all.each {|user|
      avatar_path = File.join(RAILS_ROOT, 'store', 'avatars', user.company_id.to_s, "#{user.id}")
      if File.exist?(avatar_path)
        begin
          user.avatar = File.new(avatar_path)
          user.save!
        rescue Exception => e
          str= "\nCall to paperclip raise an exception\n"
          str<< "User object inspect:\n"
          str<< user.inspect
          str<< "\nFile: #{avatar_path}\n"
          str<< "Paperclip.options hash:\n"
          str<< Paperclip.options.inspect
          p e.message + str
        end
      end
    }
  end

  def self.down
  end
end
