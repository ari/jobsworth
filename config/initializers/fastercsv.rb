if RUBY_VERSION < "1.9"
  # fastercsv has been moved in as default csv engine in 1.9
else
  require "csv"
  if !defined?(FasterCSV)
    class Object
      FasterCSV = CSV
      alias_method :FasterCSV, :CSV
    end
  end
end