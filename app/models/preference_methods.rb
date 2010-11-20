# encoding: UTF-8
# Some methods for dealing with preferences
module PreferenceMethods
  
  # Sets or creates any preferences from the given
  # params. Any preferences not included are left untouched.
  def preference_attributes=(params)
    params.each do |key, value|
      pref = preferences.detect { |p| p.key.to_s == key.to_s }
      pref ||= preferences.build(:key => key)

      pref.value = value
      pref.save
    end
  end

  # Returns the value for the given key, or nil if none found
  def preference(key)
    pref = preferences.detect { |p| p.key.to_s == key.to_s }

    return pref.value if pref
  end
end
