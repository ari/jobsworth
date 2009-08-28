module MigrationHelpers
  ###
  # Creates a foreign key in the db.
  ###
  def foreign_key(from_table, from_column, to_table)
    constraint_name = "fk_#{from_table}_#{from_column}" 

    cmd = "alter table #{from_table} "
    cmd += "add constraint #{constraint_name} "
    cmd += "foreign key (#{from_column}) "
    cmd += "references #{to_table}(id) "
    execute(cmd)
  end

  def remove_foreign_key(from_table, from_column, to_table)
    constraint_name = "fk_#{from_table}_#{from_column}" 

    execute %{alter table #{from_table} drop foreign key #{constraint_name}}
  end

  ###
  # Adds foreign keys for all tables given. Tables should be hash
  # where the target table name is the key. The key should point
  # to an array of all table names which should reference that target.
  ###
  def add_foreign_keys_for(tables)
    tables.each do |reference_name, tables|
      column_name = reference_name.to_s.singularize.foreign_key

      tables.each do |table| 
        begin
          foreign_key(table, column_name, reference_name)
        rescue
          puts "ERROR"
          puts $!
        end
      end
    end
  end

  ###
  # Removes foreign keys for all tables given.
  # See add_foreign_keys_for for the format of tables.
  ###
  def remove_foreign_keys_for(tables)
    tables.each do |reference_name, tables|
      column_name = reference_name.to_s.singularize.foreign_key
      tables.each do |table| 
        begin
          remove_foreign_key(table, column_name, reference_name) 
        rescue
          puts $!
        end
      end
    end
  end
end
