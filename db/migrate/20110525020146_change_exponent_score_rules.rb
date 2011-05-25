class ChangeExponentScoreRules < ActiveRecord::Migration
  def self.up
    change_table :score_rules do |t|
      t.change :exponent, :decimal, :precision => 5, :scale => 2, :default => 1.0
    end
  end

  def self.down
  end
end
