var jobsworth = jobsworth || {};

jobsworth.EmailAddresses = (function($) {
  function EmailAddresses(user_id) {
    this.user_id = user_id;

    this.bindEvents();
  }

  EmailAddresses.prototype.bindEvents = function() {
    var self = this;

    $('#add-email-container button').click(function() {
      var email = $('#add-email-container input#email').val();

      if (!/^\S+@\S+\.\S+$/.test(email)) {
        alert('Please input a valid email address.');
        return false;
      }

      self.addEmail(email);

      return false;
    });

    $('.email_address .set-default').live('click', function() {
      var id = $(this).parents('.email_address').data('id');
      self.setDefault(id);
      return false;
    });

    $('.email_address .delete-link').live('click', function() {
      if (confirm('Are you sure to delete the email address?')) {
        var id = $(this).parents('.email_address').data('id');
        self.deleteEmail(id);
      }
      return false;
    })
  };

  EmailAddresses.prototype.deleteEmail = function(id) {
    var jqXHR = $.post('/email_addresses/' + id, {_method: 'delete'}, function(res) {
      if (res.success) {
        $('.email_address[data-id=' + id + ']').remove();
      } else {
        alert(res.message);
      }
    });

    jqXHR.error(function() {
      alert("Sorry, there's an exception, please retry later.");
    })
  };

  EmailAddresses.prototype.setDefault = function(id) {
    var jqXHR = $.post('/email_addresses/' + id + '/default', {_method: 'put'}, function(res) {
      if (res.success) {
        $('.email_address').removeClass('default');
        $('.email_address[data-id=' + id + ']').addClass('default');
      } else {
        alert(res.message);
      }
    });

    jqXHR.error(function() {
      alert("Sorry, there's an exception, please retry later.");
    })
  };

  EmailAddresses.prototype.addEmail = function(email) {
    var data = {user_id: this.user_id, email: email};
    var jqXHR = $.post('/email_addresses', {email_address: data}, function(res) {
      if (res.success) {
        $('#emails-container').append(res.html);
        $('#add-email-container input#email').val('');
      } else {
        alert(res.message);
      }
    });

    jqXHR.error(function() {
      alert("Sorry, there's an exception, please retry later.");
    })
  };

  return EmailAddresses;
})(jQuery);