# encoding: UTF-8
module TodosHelper
  def todo_open_close_check_box(todo)
    url = "/todos/toggle_done/#{ todo.id }?task_id=#{ @task.id }"
    id = todo.id

    check_box("todo", "done", {
      :checked => todo.done?,
      :class => "button checkbox",
      :id => "button_#{ id }"
    })
  end

  def new_todo_open_close_check_box(todo)
    title = t('tasks.actions.open', task: h(todo.name))
    if todo.done?
      title = t('tasks.actions.close', task: h(todo.name))
    end

    check_box("todo", "done", { :title => title,
      :checked => todo.done?,
      :class => "button checkbox",
      :rel => "tooltip"
    })
  end

end
