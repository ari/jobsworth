# encoding: UTF-8
class ObjectFilter
  attr_accessor :logger

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
    filter_params = remove_empty_params(filter_params)
    return objects if !should_filter?(objects, filter_params)

    klass = objects.first.class
    res = objects
    
    filter_params.each do |meth, values|
      filterable = klass.const_get("FILTERABLE")
      next if !filterable.include?(meth.to_sym)

      res = res.select do |o| 
        val = o.send(meth)
        # even int params get passed in as strings, so
        # try to_s too.
        values.include?(val) or values.include?(val.to_s)
      end
    end

    return res
  end

  private

  def remove_empty_params(params)
    return if !params


    res = {}

    params.each do |meth, values|
      values = [ values ].flatten

      values.delete_if { |v| v.blank? }
      res[meth] = values if values.any?
    end

    return res
  end

  def should_filter?(objects, filter_params)
    res = true

    res &&= false if !objects
    res &&= false if !filter_params or filter_params.empty?

    klass = objects.first.class
    res &&= false if !klass.const_defined?("FILTERABLE")

    return res
  end

end
