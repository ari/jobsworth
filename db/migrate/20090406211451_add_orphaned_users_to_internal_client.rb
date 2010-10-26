class AddOrphanedUsersToInternalClient < ActiveRecord::Migration
  def self.up
    Company.all.each do |c|
      internal = c.internal_customer
      next if !internal

      orphans = c.users.select { |u| u.customer.nil? }

      orphans.each do |u|
        u.customer = internal
        u.save
      end
    end
  end

  def self.down
    # not really any way to back out of this.
  end
end
