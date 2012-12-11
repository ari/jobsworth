class MoveAssetsToTenantDirectory < ActiveRecord::Migration
  def up
    company = Company.first

    dir = File.join($CONFIG[:store_root], company.id.to_s)
    `mkdir -p #{dir}`

    # project files
    files = File.join($CONFIG[:store_root], "*.*")
    `mv #{files} #{dir}`

    # avatars
    avatars = File.join($CONFIG[:store_root], "avatars")
    `mv #{avatars} #{dir}`

    # logos
    logos = File.join($CONFIG[:store_root], "logos")
    `mv #{logos} #{dir}`
  end

  def down
  end
end
