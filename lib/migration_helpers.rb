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
end
