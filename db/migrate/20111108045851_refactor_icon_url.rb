class RefactorIconUrl < ActiveRecord::Migration
  def up
    PropertyValue.all.each do |pv|
      next unless pv.icon_url

      pv.icon_url = pv.icon_url.gsub(/\/\w+\/\w+\/(.*)/, "\\1")
      pv.save!
    end
  end

  def down
    PropertyValue.all.each do |pv|
      next unless pv.icon_url

      pv.icon_url = File.join("icons", pv.icon_url)
      pv.save!
    end
  end
end
