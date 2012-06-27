var jobsworth = jobsworth || {};

jobsworth.UserEdit = (function() {
  var $ = jQuery;

  function UserEdit(options) {
    this.options = options;
    this.bindEvents();
  }

  UserEdit.prototype.bindEvents = function() {
    var self = this;

    $("#add_email_link").click(function() {
      self.addEmail();
    })

    $("a.mark_as_default").live("click", function() {
      self.markAsDefault(this);
    })

    $("a.remove_email").live("click", function() {
      self.removeEmail(this);
    })

  }

  UserEdit.prototype.addEmail = function() {
    var html = "" +
      '<div class="control-group">' +
        '<label for="user_email"></label>' +
        '<div class="controls">' +
          '<input id="new_emails__email" name="new_emails[][email]" size="30" type="text" value="">' +
          '<span class="email_link_actions">' +
            '<a class="mark_as_default" href="#">Mark As Default</a>' +
            '<a class="remove_email" href="#"><i class="icon-trash"></i></a>' +
          '</span>' +
        '</div>' +
        '<input id="new_emails__default" name="new_emails[][default]" type="hidden" value="0">' +
      '</div>'
    $(html).appendTo("span#user_email_addresses");
  }

  UserEdit.prototype.removeEmail = function(sender) {
    $(sender).parents(".control-group").remove();
  }

  UserEdit.prototype.markAsDefault = function(sender) {
    var html = "" +
      '<span class="email_link_actions">' +
        '<a class="mark_as_default" href="#">Mark As Default</a>' +
        '<a class="remove_email" href="#"><i class="icon-trash"></i></a>' +
      '</span>'

    var default_label = '<span class="label label-info" id="default_email">Default</span>'

    $("label[for=user_email]").text("");
    $(sender).parents(".control-group").children("label").text("Email");
    $("span#user_email_addresses input[type=hidden]").val("0");
    $(sender).parents(".control-group").children("input[type=hidden]").val("1");
    $("span#user_email_addresses span#default_email").replaceWith(html);
    $(sender).parents(".control-group").prependTo("span#user_email_addresses");
    $(sender).parents(".email_link_actions").replaceWith(default_label);
  }

  return UserEdit;
})();

