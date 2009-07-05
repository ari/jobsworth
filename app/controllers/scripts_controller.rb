class ScriptsController < ApplicationController
  def index
    if !current_user.admin?
      flash['notice'] = _("Only admins can edit company settings.")
      redirect_from_last
      return
    end

    cmd = "#{ RAILS_ROOT }/lib/scripts/#{ params[:script] }"
    cmd = "#{ RAILS_ROOT }/script/runner -e #{ RAILS_ENV } #{ cmd }"
    
    
    result = ""
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thread| 
      result += stdout.read
      errors = stderr.read
      if !errors.blank?
        result += "\n#{ errors }"
      end
    end

    response.content_type = "text/plain"
    render :text => result
  end
end
