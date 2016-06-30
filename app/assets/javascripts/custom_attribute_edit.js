var jobsworth = jobsworth || {};

jobsworth.CustomAttributeEdit = (function ($) {

  function CustomAttributeEdit(options) {
    this.options = options;
    this.init();
    this.bind();
  }

  CustomAttributeEdit.prototype.bind = function () {
    var self = this;

    $("input.preset-checkbox").live("change", function () {
      self.presetChange(this);
    })
  };

  CustomAttributeEdit.prototype.init = function () {
    var self = this;
  };

  CustomAttributeEdit.prototype.presetChange = function (checkbox) {
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
  };

  return CustomAttributeEdit;
})(jQuery);
