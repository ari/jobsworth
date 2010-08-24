unless $gems_rake_task
  if Rails.version <= "2.3.7"
    $stderr.puts "rails_xss requires Rails 2.3.8 or later. Please upgrade to enable automatic HTML safety."
  else
    require 'rails_xss'
  end
end
