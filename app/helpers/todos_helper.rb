module TodosHelper

  def delete_todo_link(todo)
    image = image_tag("cross_small.png", :class => "tooltip",
                      :title => _("Delete <b>%s</b>.", h(todo.name)).html_safe)
    path = todo_path(todo, :task_id => @task.id) 

    link_to_remote(image, :url => path, :method => :delete,
                   :update => "todo-container")
  end

  def todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', todo.name).html_safe
    if todo.done?
      title = _("Close <b>%s</b", todo.name).html_safe
    end

    url = "/todos/toggle_done/#{ todo.id }?task_id=#{ @task.id }"
    id = todo.id

    check_box("todo", "done", { :title => title,
                :checked => todo.done?,
                :class => "button tooltip checkbox",
                :id => "button_#{ id }",
                :onclick => "jQuery('.todo-container').load('#{ url }')"
              })
  end

  def new_todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', todo.name).html_safe
    if todo.done?
      title = _("Close <b>%s</b", todo.name).html_safe
    end

    check_box("todo", "done", { :title => title,
                :checked => todo.done?,
                :class => "button tooltip checkbox",
                :onclick => "new_todo_open_close_check(jQuery(this).attr('checked'), this,
                            '#{Time.now}', '#{formatted_datetime_for_current_user(Time.now)}',
                            '#{current_user.name}', '#{current_user.id}')"
              })
  end

  def add_new_todo
    link_to_function(_("New To-do Item")) do |page|
      todo = Todo.new(:creator_id => current_user.id)
      page.insert_html(:bottom, "todos-clone", :partial => "/todos/new_todo",
                       :locals => { :todo => todo})
      page << "addNewTodoKeyListenerForUncreatedTask(this, 'new');new_task_form();"
    end
  end

end
