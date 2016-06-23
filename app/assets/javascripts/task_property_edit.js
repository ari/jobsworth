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
      var pv_element = $(this).parents('.property_value');
      var pv_id = pv_element.data("property-value-id");
      if (/\d+/.test(pv_id)) {
        self.removePropertyValue(pv_id, function(){ pv_element.remove(); });
      } else {
        pv_element.remove();
      }
      return false;
    })

    $("input.default").live('change', function(){
      $('.default').prop('checked', false);
      $(this).prop('checked', true);
    })

    $("input.preset-checkbox").live("change", function() {
      self.presetChange(this);
    })
  }

  TaskPropertyEdit.prototype.init = function() {
    var self = this;

    $("#property_values").sortable({
      handle: ".handle",
      update: function(event, ui) { self.reorderPropertyValue(event, ui); }
    });
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

  TaskPropertyEdit.prototype.removePropertyValue = function(pv_id, callback) {
    $("#remove_property_value_dialog").remove();
    $.get("/properties/remove_property_value_dialog", {property_value_id: pv_id}, function(data) {
      $('body').prepend(data);
      $('#remove_property_value_dialog').modal('show');

      $('#remove_property_value_form').bind("ajax:success", function(event, json, xhr) {
        if (json.success) {
          $('#remove_property_value_dialog').modal('hide')
          callback();
        } else {
          alert(json.message);
        }
      });
    });
  }

  TaskPropertyEdit.prototype.reorderPropertyValue = function(event, ui) {
    var pvs = [];
      $('.property_value.clearfix').each(function(index, element){
        pvs.push($(element).prop("id").replace("property_value_", ""));
      });
    $.post('/properties/order', { property_values: pvs } );
  }

  return TaskPropertyEdit;
})(jQuery);
