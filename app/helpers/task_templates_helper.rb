module TaskTemplatesHelper
 def create_task_from_template_tag(object)
    unless object.new_record?
      submit_tag(_("Create task from this template"), :id=>'create_task_from_template', :class => 'nolabel', :style=>'float:none;')
    end
  end
end
