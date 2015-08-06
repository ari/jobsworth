class AddCommentPrivateToUsers < ActiveRecord::Migration
  def change
      add_column :users, :comment_private_by_default, :boolean, default: false
  end
end
