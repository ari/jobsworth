class CreateSnippets < ActiveRecord::Migration
  def change
    create_table :snippets do |t|
      t.string :name
      t.text :body
      t.integer :company_id
      t.integer :user_id

      t.timestamps
    end
  end
end
