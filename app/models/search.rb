# encoding: UTF-8
class Search
  ###
  # Returns an array to use as the conditions value
  # in a find.
  # When used in a find, the  id and any given fields
  # will be searched and any objects with a ANY of the
  # given strings as a starting substring will be returned.
  # If a number is given, any objects with that id will be
  # returned, but so will any objects with that number in fields.
  #
  # If options[:search_by_id] is false, ids won't be searched automatically.
  # If options[:start_search_only], only values starting with the given string will be returned.

  ###
  def self.search_conditions_for(strings, fields = [ :name ], options = {})
    search_by_id = options.has_key?(:search_by_id) ? options[:search_by_id] : true
    id_field= options.has_key?(:table) ? "#{options[:table]}.id" : "id"

    conds = []
    cond_params = []

    if search_by_id
      strings.each do |s|
        next if s.to_i <= 0
        conds << "#{id_field} = ?"
        cond_params << s
      end
    end

    fields.each do |field|
      strings.each do |s|
        next if s.strip.blank?
        conds << "lower(#{ field }) like ?"
        if options[:start_search_only]
          cond_params << "#{ s.downcase.strip }%"
        else
          cond_params << "%#{ s.downcase.strip }%"
        end
      end
    end

    if conds.any?
      full_conditions = [ conds.join(" or ") ] + cond_params
      sanitized = ActiveRecord::Base.send(:sanitize_sql_array, full_conditions)
      return "(#{ sanitized })"
    end
  end
end
