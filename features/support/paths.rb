module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name, query_arguments = {})
    case page_name

    when /^the home\s?page$/
      '/'
    when /the ([A-Z]\w+) (\d+) (edit) page/
      record = $1.constantize.find($2)
      self.send([$3, (record.respond_to? :friendly_id) ? record.friendly_id : $1.underscore.singularize, "path"].join("_").to_sym, $2, query_arguments)

      # Add more mappings here.
      # Here is an example that pulls values out of the Regexp:
      #
      #   when /^(.*)'s profile page$/i
      #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /^the (.*) page$/
          path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym, query_arguments)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)

