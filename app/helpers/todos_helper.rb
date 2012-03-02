# encoding: UTF-8
module TodosHelper

  def delete_todo_link(todo)
    link_to_function '<i class="icon-remove"></i>'.html_safe, "deleteTodo(#{todo.id}, #{@task.id})"
  end

  def todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', h(todo.name))
    if todo.done?
      title = _("Close <b>%s</b>", h(todo.name))
    end

    url = "/todos/toggle_done/#{ todo.id }?task_id=#{ @task.id }"
    id = todo.id

    check_box("todo", "done", { :title => title,
                :checked => todo.done?,
                :class => "button jtooltip checkbox",
                :id => "button_#{ id }",
                :onclick => "toogleDone(this);"
              })
  end

  def new_todo_open_close_check_box(todo)
    title = _('Open <b>%s</b>', h(todo.name))
    if todo.done?
      title = _("Close <b>%s</b>", h(todo.name))
    end

    check_box("todo", "done", { :title => title,
                :checked => todo.done?,
                :class => "button jtooltip checkbox",
                :onclick => "todoOpenCloseCheckForUncreatedTask(jQuery(this).attr('checked'), this)"
              })
  end

end
