var TaskEditor = (function() {

  function bind() {
      var task = this;
      var $ = jQuery;

      // project select field
      var project_options = {
          loadurl: '/tasks/projects_select_json/' + task.task_id,
          type: 'select'
      }
      $.extend(project_options, this.options);

      this.$project_span.editable(function(value, settings) {
          var submitdata = {};
          submitdata['task[project_id]'] = value;
          submitdata['_method'] = 'put';
          submitdata['format'] = 'js';

          $(this).html(settings.indicator);

          var self = this;
          $.post("/tasks/" + task.task_id, submitdata, function(data) {
              $.get('/tasks/projects_select_json/' + task.task_id, function(json) {
                  $(self).html(json[value]);
              }, 'json')
          }, 'json');

      }, project_options);

      // milestone select field
      var milestone_options = {
          loadurl: '/tasks/milestones_select_json/' + task.task_id,
          type: 'select'
      }
      $.extend(milestone_options, task.options);

      this.$milestone_span.editable(function(value, settings) {
          var submitdata = {};
          submitdata['task[milestone_id]'] = value;
          submitdata['_method'] = 'put';
          submitdata['format'] = 'js';

          $(this).html(settings.indicator);

          var self = this;
          $.post("/tasks/" + task.task_id, submitdata, function(data) {
              $.get('/tasks/milestones_select_json/' + task.task_id, function(json) {
                  $(self).html(json[value]);
              }, 'json')
          }, 'json');

      }, milestone_options);
  }

  function init() {
      var $ = jQuery;

      this.$project_span = $("#task_project_span"),
      this.$milestone_span = $("#task_milestone_span")
      
  }

  function TaskEditor(options) {
      // set editable options
      this.options = {
          tooltip: 'Click to edit...',
          indicator: 'Saving...',
          submit: "OK"
      }

      jQuery.extend(true, this, options);

      // init variables & bind events
      init.call(this);
      bind.call(this);

      //public methods
  }

  return TaskEditor;
})();
