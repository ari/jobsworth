class DropPagesTable < ActiveRecord::Migration
  def up
    drop_table :pages
  end

  def down
  end
end
