# encoding: UTF-8

require 'open3'
require 'pathname'

class ScriptsController < ApplicationController
  def index
    if !current_user.admin?
      flash['notice'] = _("Only admins can edit company settings.")
      redirect_from_last
      return
    end

    cmd = "#{Rails.root}/lib/scripts/#{ params[:script] }"
    cmd = "#{Rails.root}/script/rails runner -e #{ Rails.env } #{ cmd }"


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
