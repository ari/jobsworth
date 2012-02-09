class AddResetPasswordSentAtToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.datetime :reset_password_sent_at
    end
  end
end
