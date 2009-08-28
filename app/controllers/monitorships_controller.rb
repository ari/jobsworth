class MonitorshipsController < ApplicationController

  def create
    if params[:topic_id]
      @monitorship = Monitorship.find_or_create_by_user_id_and_monitorship_id_and_monitorship_type(current_user.id, params[:topic_id], 'topic')
    else
      @monitorship = Monitorship.find_or_create_by_user_id_and_monitorship_id_and_monitorship_type(current_user.id, params[:forum_id], 'forum')
    end
    @monitorship.update_attribute :active, true
    respond_to do |format|
      if params[:topic_id]
        format.html { redirect_to topic_path(params[:forum_id], params[:topic_id]) }
      else
        format.html { redirect_to forum_path(params[:forum_id]) }
      end
      format.js
    end
  end

  def destroy
    if params[:topic_id]
      Monitorship.update_all ['active = ?', false], ['user_id = ? and monitorship_id = ? and monitorship_type = ?', current_user.id, params[:topic_id], 'topic']
    else
      Monitorship.update_all ['active = ?', false], ['user_id = ? and monitorship_id = ? and monitorship_type = ?', current_user.id, params[:forum_id], 'forum']
    end
    respond_to do |format|
      if params[:topic_id]
        format.html { redirect_to topic_path(params[:forum_id], params[:topic_id]) }
      else
        format.html { redirect_to forum_path(params[:forum_id]) }
      end
      format.js
    end
  end
end
