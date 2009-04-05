class Search
  ###
  # Returns an array to use as the conditions value
  # in a find.
  # When used in a find, the  id and any given fields 
  # will be searched and any objects with a ANY of the 
  # given strings as a substring will be returned.
  # If a number is given, any objects with that id will be 
  # returned, but so will any objects with that number in fields.
  ###
  def self.search_conditions_for(strings, fields = [ :name ])
    conds = []
    cond_params = []
    
    strings.each do |s|
      next if s.to_i <= 0
      conds << "id = ?"
      cond_params << s
    end
    
    fields.each do |field|
      strings.each do |s|
        next if s.strip.blank?
        conds << "lower(#{ field }) like ?"
        cond_params << "%#{ s.downcase.strip }%"
      end
    end

    if conds.any?
      return [ conds.join(" or ") ] + cond_params
    end
  end
end
