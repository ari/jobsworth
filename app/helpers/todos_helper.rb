module TodosHelper

  def delete_todo_link(todo)
    image = image_tag("cross_small.png", :class => "tooltip",
                      :title => _("Delete <b>%s</b>.", h(todo.name)))
    path = todo_path(todo, :task_id => todo.task.id)

    link_to_remote(image, :url => path, :method => :delete,
                   :update => "todo-container")
  end

  def todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', todo.name)
    if todo.done?
      title = _("Close <b>%s</b", todo.name)
    end

    url = "/todos/toggle_done/#{ todo.id }?task_id=#{ todo.task.id }"

    check_box("todo", "done", { :title => title, 
                :checked => todo.done?,
                :class => "button tooltip checkbox", 
                :id => "button_#{ todo.id }", 
                :onclick => "jQuery('.todo-container').load('#{ url }')"
              })
  end

end
