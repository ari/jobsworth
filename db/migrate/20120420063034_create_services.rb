class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :name
      t.text :description
      t.integer :company_id

      t.timestamps
    end
  end
end
