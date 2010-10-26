class AddCompanySubdomain < ActiveRecord::Migration
  def self.up
    add_column :companies, :subdomain, :string, :null => false
    Company.all.each do |c|
      subdomain = c.name.to_s.gsub(/[\W_ ]+/,'-').gsub(/^-+/, '').gsub(/-+$/,'').gsub(/^[0-9]+/,'').downcase
      if subdomain.blank?
	subdomain = MD5.hexdigest((c.object_id + rand(255)).to_s)
      end
      c.subdomain = subdomain
      c.save
    end
    add_index :companies, :subdomain, :unique => true
  end

  def self.down
    remove_column :companies, :subdomain
  end
end
