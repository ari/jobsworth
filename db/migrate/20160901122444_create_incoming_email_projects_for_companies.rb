class CreateIncomingEmailProjectsForCompanies < ActiveRecord::Migration
  
  def change
    Company.find_each do |company|
      unless company.preference('incoming_email_project').present?
        project = company.projects.create!(name: 'Incoming Project', customer_id: company.customers.first.id) if company.customers.any?
        company.preferences.create!(key: 'incoming_email_project', value: project.id) if project.present?
      end
    end
  end
end
