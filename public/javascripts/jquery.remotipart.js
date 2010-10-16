jQuery(function ($) {
    $.fn.extend({
		/**
	     * Handles execution of remote calls involving file uploads, firing overridable events along the way
	     */
	    callRemotipart: function () {
	        var el      = this,
	            url     = el.attr('action');

	        if (url === undefined) {
	          throw "No URL specified for remote call (action must be present).";
	        } else {
	            if (el.triggerAndReturn('ajax:before')) {
					if(url.substr(-3) != '.js') url += '?format=js'; //force rails to respond to respond to the request with :format = js
	                el.ajaxSubmit({
	                    url: url,
	                    dataType: 'json',
	                    beforeSend: function (xhr) {
	                        el.trigger('ajax:loading', xhr);
	                    },
	                    success: function (data, status, xhr) {
	                        el.trigger('ajax:success', [data, status, xhr]);
	                    },
	                    complete: function (xhr) {
	                        el.trigger('ajax:complete', xhr);
	                    },
	                    error: function (xhr, status, error) {
	                        el.trigger('ajax:failure', [xhr, status, error]);
	                    }
	                });
	            }

	            el.trigger('ajax:after');
	        }
		},
		_callRemote: $.fn.callRemote, //store the original rails callRemote
		callRemote: function(){ //override the rails callRemote and check for a file input
			if(this.find('input:file').length){
				this.callRemotipart();
			} else {
				this._callRemote();
			}
		}
	});

});