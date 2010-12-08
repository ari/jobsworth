# encoding: UTF-8
module TriggersHelper
  def render_action_partial(fields)
    render :partial=> "/actions/#{fields.object.class.name.demodulize.underscore}", :locals=>{ :fields=>fields}
  end
end
