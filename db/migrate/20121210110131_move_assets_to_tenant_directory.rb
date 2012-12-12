class MoveAssetsToTenantDirectory < ActiveRecord::Migration
  def up
    company = Company.first

    parent_dir = File.expand_path("..", $CONFIG[:store_root])

    # mv assets to temp dir
    tmp_dir = File.join(parent_dir, File.basename($CONFIG[:store_root]) + ".tmp")
    puts `mv #{$CONFIG[:store_root]} #{tmp_dir}`

    # mv temp dir to dest dir
    dest_dir = File.join($CONFIG[:store_root], company.id.to_s)
    puts `mkdir  #{$CONFIG[:store_root]}`
    puts `mv #{tmp_dir} #{dest_dir}`
  end

  def down
  end
end
