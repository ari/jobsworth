# encoding: UTF-8
module TodosHelper
  def todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', h(todo.name))
    if todo.done?
      title = _("Close <b>%s</b>", h(todo.name))
    end

    url = "/todos/toggle_done/#{ todo.id }?task_id=#{ @task.id }"
    id = todo.id

    check_box("todo", "done", { :title => title,
      :checked => todo.done?,
      :class => "button checkbox",
      :rel => "tooltip",
      :id => "button_#{ id }"
    })
  end

  def new_todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', h(todo.name))
    if todo.done?
      title = _("Close <b>%s</b>", h(todo.name))
    end

    check_box("todo", "done", { :title => title,
      :checked => todo.done?,
      :class => "button checkbox",
      :rel => "tooltip"
    })
  end

end
