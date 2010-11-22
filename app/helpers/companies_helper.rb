# encoding: UTF-8
module CompaniesHelper

  # A select tag to choose the company's default incoming email
  # location.
  def incoming_email_select_tag
    pref_name = "incoming_email_project"
    name = "company[preference_attributes][#{ pref_name }]"
    options = [ "" ] + objects_to_names_and_ids(@company.projects)
    options = options_for_select(options, :selected => @company.preference(pref_name).to_i)

    return select_tag(name, options)
  end

  # Returns an array of file names for custom scripts stored in the
  # lib/scripts dir
  def all_custom_scripts
    Dir.glob("#{Rails.root}/lib/scripts/*.rb").map { |f| File.basename(f) }
  end
end
