class ChangeProjectNotesToUseNotable < ActiveRecord::Migration
  def self.up

    sql = "update pages set notable_type = 'Project' where project_id is not null"
    Page.connection.execute(sql)
    sql = "update pages set notable_id = project_id where project_id is not null"
    Page.connection.execute(sql)

    remove_column :pages, :project_id
  end

  def self.down
    add_column :pages, :project_id, :integer

    sql = "update pages set project_id = notable_id where notable_type = 'Project'"
    Page.connection.execute(sql)
  end
end
