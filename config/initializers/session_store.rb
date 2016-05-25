# Be sure to restart your server when you modify this file.
if defined?($servlet_context)
  require 'action_controller/session/java_servlet_store'
  # tell rails to use the java container's session store
  Rails.application.config.session_store :java_servlet_store
else
  Rails.application.config.session_store :active_record_store,
                                       :key => '_jobsworth_session',
                                       :expire_after => 3.hours
end


# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# Rails.application.config.session_store :active_record_store
