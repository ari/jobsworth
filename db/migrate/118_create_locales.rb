
class CreateLocales < ActiveRecord::Migration
  def self.up
    create_table :locales do |t|
      t.string :locale
      
      t.text :key
      t.text :singular
      t.text :plural
    
      t.references :user, :default => nil

      t.timestamps
    end

    execute("alter table locales modify locales.key varchar(255) character set utf8 collate utf8_bin;")
    
    add_index :locales, [:locale, :key], :unique => true
    
  end

  def self.down
    drop_table :locales
  end
end
