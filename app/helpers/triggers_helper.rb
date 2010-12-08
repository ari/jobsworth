# encoding: UTF-8
module TriggersHelper
  def render_action_partial(action)
    render :partial=> "/actions/#{action.class.name.demodulize.underscore}", :locals=>{ :action=> action }
  end
end
