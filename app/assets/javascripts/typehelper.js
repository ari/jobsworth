TypeHelper = (function() {

  var $ = jQuery;

  function TypeHelper(input, url, minLength) {
    this.input = input;
    this.url = url;
    this.helperClass = "type_helper" + new Date().valueOf();
    this.minLength = (minLength || 1);

    bindEvents.call(this);
  }

  function bindEvents() {
    var self = this;
    this.input.keyup(function() {
      if (self.input.val().length < self.minLength) {
        $("." + self.helperClass).remove();
        return;
      }
      show.call(self, self.input.val());
    }).focusin(function() {
      if (self.input.val().length < 1) return;
      show.call(self, self.input.val());
    })
  }

  function show(term) {
    var self = this;
    $.get(this.url, {term: term}, function(res) {
      if (! res.success) return;
      if (self.input.val() != term) return;

      $("." + self.helperClass).remove();

      // show helper
      var helper = $(res.html);
      var offset = self.input.offset();
      var height = self.input.outerHeight();
      helper.addClass(self.helperClass);
      helper.css("position", "absolute");
      helper.css("left", offset.left + "px");
      helper.css("top", offset.top + height + "px");
      helper.css("display", "block");
      $("body").append(helper);

      var mouse_is_inside = false;
      helper.hover(function(){
        mouse_is_inside=true;
      }, function(){
        mouse_is_inside=false;
      });
      $("body").mouseup(function(){
        if(!mouse_is_inside) helper.remove();
      });
    })
  }

  return TypeHelper;
})()
