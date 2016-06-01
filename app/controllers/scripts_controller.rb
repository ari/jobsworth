# encoding: UTF-8

require 'open3'
require 'pathname'

class ScriptsController < ApplicationController
  before_filter :authorize_user_is_admin
  before_filter :check_script

  def index
    Dir.chdir(Rails.root) do |_|
      bash = `which bash`.strip
      ruby = 'script/jruby_jar_exec'
      runner = 'script/rails runner -e development'
      script = "#{Setting.custom_scripts_root}/#{ params[:script] }".inspect
      cmd = "#{bash} #{ruby} #{runner} #{script}"
      Rails.logger.info cmd
      @result = ''
      command_execution(cmd)
      response.content_type = 'text/plain'
      render :text => @result
    end
  end


  def send_tasks_report
    Dir.chdir(Rails.root) do |root|
      if defined?($servlet_context)
        ruby = 'script/jruby_jar_exec'
      else
        ruby = 'ruby'
      end
      script = "#{Setting.custom_scripts_root}/#{ params[:script] }".inspect
      cmd = "#{ruby} #{script} #{current_company.id} > tmp/report.html"
      Rails.logger.info cmd
      File.delete('tmp/report.html') if File.exist?('tmp/report.html')
      @result = ''
      command_execution(cmd)
      TaskReportMailer.send_report('ari@ish.com.au').deliver_now if File.exist?('tmp/report.html')
      redirect_to :back, flash: File.exist?('tmp/report.html') ? {succes: t('.successful_sending') } : {error: t('.sending_error') }
    end
  end

  private

  def command_execution(cmd)
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thread|
      @result += stdout.read
      errors = stderr.read
      if !errors.blank?
        @result += "\n#{ errors }"
      end
    end
  end

  def check_script
    send_tasks_report if params[:script] == 'tasks_report.rb'
  end
end
