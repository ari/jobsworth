module TodosHelper

  def delete_todo_link(todo)
    image = image_tag("cross_small.png", :class => "tooltip",
                      :title => _("Delete <b>%s</b>.", h(todo.name)).html_safe)
    path = @task ? todo_path(todo, :task_id => @task.id) : "/todos/destroy_clone/#{todo.position}"

    link_to_remote(image, :url => path, :method => :delete,
                   :update => "todo-container")
  end

  def todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', todo.name).html_safe
    if todo.done?
      title = _("Close <b>%s</b", todo.name).html_safe
    end

    if @task
      url = "/todos/toggle_done/#{ todo.id }?task_id=#{ @task.id }"
    else
      url = "/todos/toggle_todo_clone_done/#{ todo.position }"
    end

    check_box("todo", "done", { :title => title,
                :checked => todo.done?,
                :class => "button tooltip checkbox",
                :id => "button_#{ todo.id }",
                :onclick => "jQuery('.todo-container').load('#{ url }')"
              })
  end

end
