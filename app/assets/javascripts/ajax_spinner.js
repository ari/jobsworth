var jobsworth = jobsworth || {};

jobsworth.AjaxSpinner = (function($){
  function AjaxSpinner(element) {
    this.element = element;
    this.count = 0;
    this.bind();
  }

  AjaxSpinner.prototype.bind = function() {
    var self = this;

    $(document).ajaxSend(function(){
      self.count++;
      $(self.element).show('fast');
     });

    $(document).ajaxComplete(function(){
      self.count--;
      if (self.count <= 0) {
        $(self.element).hide('fast');
      }
    });

    $(document).mousemove(function(e) {
      if ($(self.element).is(':visible')) {
        $(self.element).css({
          top: (e.pageY  - 8) + "px",
          left: (e.pageX + 10) + "px"
        });
      }
    });
  };

  return AjaxSpinner;
})(jQuery);