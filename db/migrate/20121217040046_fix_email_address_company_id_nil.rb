class FixEmailAddressCompanyIdNil < ActiveRecord::Migration
  def up
    if Company.count > 1
      puts "WARNING: The script can't auto fix email addresses of multiple company install."
      return
    end

    company = Company.first
    EmailAddress.where(:company_id => nil).each do |ea|
      ea.update_column(:company_id, company.id)
      puts "Set company of #{ea.email} to #{company.name}"
    end
  end

  def down
  end
end
