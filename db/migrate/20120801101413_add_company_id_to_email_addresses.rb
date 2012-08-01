class AddCompanyIdToEmailAddresses < ActiveRecord::Migration
  def change
    add_column :email_addresses, :company_id, :integer

    Company.count == 1 and EmailAddress.all.each do |ea|
      ea.company_id = Company.first.id
      ea.save
    end
  end
end
