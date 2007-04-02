# Simple real-time chat.
class ShoutController < ApplicationController

  cache_sweeper :shout_sweeper, :only => :add_ajax

  def add_ajax
    shout = Shout.new(params[:shout])
    shout.user_id = session[:user].id
    shout.company_id = session[:user].company_id
    shout.save unless shout.body.nil?
    @shouts = Shout.find(:all, :conditions => ["company_id = ?", session[:user].company.id], :limit => 7, :order => "id desc")

    partial_to_string = render_to_string(:action => "list_ajax")
    Juggernaut.send("#{partial_to_string}", ["chat_#{session[:user].company_id}"])
    render :nothing => true
  end

  def list_ajax
    @shouts = Shout.find(:all, :conditions => ["company_id = ?", session[:user].company.id], :limit => 7, :order => "id desc")
  end
end
