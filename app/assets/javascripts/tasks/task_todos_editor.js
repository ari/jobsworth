// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var jobsworth = jobsworth || {}
jobsworth.tasks = jobsworth.tasks || {}

jobsworth.tasks.TaskTodosEditor = (function($) {
  function TaskTodosEditor(options) {
    this.options = options;
    this.el = this.options.el;
    this.initialize();
    this.bindEvents();   
  }

  TaskTodosEditor.prototype.initialize = function() {
    var self = this;
    $('.task-todo').sortable({update: function(event,ui){
      var todos= new Array();
      $.each($('.task-todo li'),
        function(index, element){
          var position = $('input#todo_position', element);
          position.val(index+1);
          todos[index]= {id: $('input#todo_id', element).val(), position: index+1} ;
        });
        $.ajax({ url: '/todos/reorder', data: {task_id: self.options.taskId, todos: todos }, type: 'POST' });
      }
    });
  }

  TaskTodosEditor.prototype.bindEvents = function() {
    var self = this;

    $(this.el).on('click', ".toggle-todo-edit", function() {
      self.toggleTodoEdit(this);
      return false;
    });

    // update todo for existing task
    $(this.el).on('keypress', '.existing-task .todo .edit input', function(key) {
      var todo = $(this).parents(".todo");
      var todoId = todo.data("id");

      if (key.keyCode == 13) {
        $(".todo-container").load("/todos/update/" + todoId,  {
          "_method": "PUT",
          task_id: self.options.taskId,
          "todo[name]": $(this).val()
        });

        key.stopPropagation();
        return false;
      }
    });

    // update todo for new task
    $(this.el).on('keypress', ".new-task .todo .edit input", function(key) {
      if (key.keyCode != 13) return;

      var li_element = $(this).parents('li.todo');
      li_element.children(".display").show();
      li_element.children(".display").text($(this).val());
      li_element.children(".edit").children("input").val($(this).val());
      li_element.children(".edit").hide();
      li_element.removeClass("editing");

      key.stopPropagation();
      return false;
    })

    // new todo for existing task
    $(this.el).on('keypress', "#new-todo-for-existing-task .edit input", function(key) {
      if (key.keyCode != 13) return;

      $.ajax({
        url: '/todos/create?task_id='+ self.options.taskId + '&todo[name]=' + $(this).val(),
        type: 'POST',
        dataType: 'json',
        success:function(response) {
          $('.todo-container').html(response.todos_html);
          $('#todo-status-' + response.task_dom_id).html(response.todos_status);
        },
        beforeSend:function() { showProgress(); },
        complete:function() { hideProgress(); }
      });

      key.stopPropagation();
      return false;
    });

    // new todo for new task
    $(this.el).on('keypress', '#new-todo-for-new-task .edit input', function(key) {
      if (key.keyCode != 13) return;

      var li_element = $($('#new-todo-for-new-task').data('todo'));
      $('#todos-clone').append(li_element);

      li_element.children(".display").show();
      li_element.children(".display").text($(this).val());
      li_element.children(".edit").children("input").val($(this).val());
      li_element.children(".edit").hide();
      $(this).val('');

      key.stopPropagation();
      return false;
    })

    $(this.el).on('change', '.new-task .checkbox', function() {
      var checkbox = this;
      var todoName = '';

      if ($(this).siblings(".edit").is(':visible')){
        todoName = $(this).siblings(".edit").children('input').val();
      } else {
        todoName = $(this).siblings(".display").text();
      }

      $.ajax({
        url: '/todos/toggle_done_for_uncreated_task/' + this.checked + '?name=' + todoName,
        dataType: 'html',
        success:function(response) {
          $(checkbox).parent().replaceWith(response);
        },
        beforeSend: function(){ showProgress(); },
        complete: function(){ hideProgress(); },
        error:function (xhr, thrownError) {
          alert("Invalid request");
        }
      });
    });

    $(this.el).on('change', '.existing-task .checkbox', function() {
      var todo = $(this).parents(".todo");
      var todoId = todo.data("id");

      $.ajax({
        url: '/todos/' + todoId + '/toggle_done/' + '?task_id=' + self.options.taskId + '&format=json',
        dataType: 'json',
        success:function(response) {
          $('.todo-container').html(response.todos_html);
          $('#todo-status-' + response.task_dom_id).html(response.todos_status);
        },
        beforeSend:function() { showProgress(); },
        complete:function() { hideProgress(); }
      });
    })

    $(this.el).on("click", '.existing-task .todo a.delete_todo', function() {
      var todo = $(this).parents(".todo");
      var todoId = todo.data("id");
      var link = this;

      $.ajax({
        url: '/todos/' + todoId + '?task_id=' + self.options.taskId,
        dataType: 'json',
        type: 'delete',
        success:function(response) {
          jQuery('#todo-status-' + response.task_dom_id).html(response.todos_status);
          jQuery('#todos-' + todoId).remove();
        },
        beforeSend:function() { showProgress(); },
        complete:function() {
          hideProgress();
          $(link).parents('.todo').remove();
        }
      });

      return false;

    });
  }

  TaskTodosEditor.prototype.toggleTodoEdit = function(sender) {
    var todo = $(sender).parents(".todo");
    var display = todo.find(".display");
    var edit = todo.find(".edit");
    todo.toggleClass("editing");
    display.toggle();
    edit.toggle();
  }

  return TaskTodosEditor;
})(jQuery)
