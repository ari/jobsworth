class Filter

  ###
  # Runs through the given objects and returns only
  # those which return one of the given values for each
  # method given. The methods must be declared in the class in
  # a class variable called FILTERABLE.
  # 
  # For example, to only include objects that return "a", or "b" 
  # from a method called "name", the filter_params should be:
  # { :name => [ "a", "b" ] }.
  #
  # Any filters based on methods not in FILTERABLE are ignored.
  ###
  def filter(objects, filter_params = {})
    return objects if !objects or filter_params.empty?
   
    klass = objects.first.class
    return objects if !klass.const_defined?("FILTERABLE")

    res = objects
    
    filter_params.each do |meth, values|
      filterable = klass.const_get("FILTERABLE")
      next if !filterable.include?(meth.to_sym)

      res = res.select { |o| values.include?(o.send(meth)) }
    end

    return res
  end
end
