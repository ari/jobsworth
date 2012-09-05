var jobsworth = jobsworth || {}

jobsworth.TaskPropertyEdit = (function($){

  function TaskPropertyEdit(options) {
    this.options = options;
    this.init();
    this.bind();
  }

  TaskPropertyEdit.prototype.bind = function() {
    var self = this;

    $("#add_value_link").click(function(){
      $('#property_values').append($(this).data('property'));
      return false;
    });

    $(".remove_property_value_link").live('click', function(){
      $(this).parents('.property_value').remove();
    })

    $("input.default").live('change', function(){
      $('.default').attr('checked', false);
      $(this).attr('checked', true);
    })
  }

  TaskPropertyEdit.prototype.init = function() {
    var self = this;

    $("#property_values").sortable({
      handle: ".handle",
      update: function(event, ui) { self.reorderPropertyValue(event, ui); }
    });

    $("input.preset-checkbox").live("change", function() {
      self.presetChange(this);
    })
  }

  TaskPropertyEdit.prototype.presetChange = function(checkbox) {
    checkbox = $(checkbox);
    var preset = checkbox.is(":checked");

    var parent = checkbox.parents(".attribute");
    var maxLength = parent.find(".max_length");
    var choices = parent.find(".choices");
    var choiceLink = parent.find(".add_choice_link");
    var multiple = parent.find(".multiple");

    if (preset) {
      multiple.hide().find("input").attr("checked", false);
      maxLength.hide().find("input").val("");
      choices.show();
      choiceLink.show();
    }
    else {
      multiple.show();
      maxLength.show();
      choices.hide().html("");
      choiceLink.hide();
    }
  }

  TaskPropertyEdit.prototype.reorderPropertyValue = function(event, ui) {
    var pvs = [];
    $.each(
      $('li.property_value'),
      function(index, element){
        pvs.push($(element).attr("id").replace("property_value_", ""));
      }
    );
    $.post('/properties/order', { property_values: pvs } );
  }

  return TaskPropertyEdit;
})(jQuery);
