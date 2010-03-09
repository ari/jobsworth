module TaskTemplatesHelper
  def create_task_from_template_tag(object)
    unless object.new_record?
      submit_tag(_("Create task from this template"), :id=>'create_task_from_template', :class => 'nolabel', :style=>'float:none;')
    end
  end
  # Renders the last template the current user looked at
  def render_last_task
    @task = Template.find_by_id(session[:last_template_id],
                         :conditions => [ "project_id IN (#{ current_project_ids }) AND company_id = ?", current_user.company_id ])
    if @task
      return render_to_string(:template => "tasks/edit", :layout => false)
    end
  end
end
