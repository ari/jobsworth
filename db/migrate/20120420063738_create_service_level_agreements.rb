class CreateServiceLevelAgreements < ActiveRecord::Migration
  def change
    create_table :service_level_agreements do |t|
      t.integer :service_id
      t.integer :customer_id
      t.boolean :billable
      t.integer :company_id

      t.timestamps
    end
  end
end
