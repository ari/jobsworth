/* 
 * Auto Expanding Text Area
 * by Chrys Bader (www.chrysbader.com)
 * http://github.com/akaihola/jquery-autogrow/raw/38bd2abb1a8399f3c56cd69897f3d9c2940918d5/jquery.autogrow.js
 *
 * Copyright (c) 2008 Chrys Bader (www.chrysbader.com)
 * Licensed under the GPL (GPL-LICENSE.txt) license. 
 */
 
(function(jQuery) {
		  
	var self = null;
 
	jQuery.fn.autogrow = function(o)
	{	
		return this.each(function() {
			new jQuery.autogrow(this, o);
		});
	};
	

    /**
     * The autogrow object.
     *
     * @constructor
     * @name jQuery.autogrow
     * @param Object e The textarea to create the autogrow for.
     * @param Hash o A set of key/value pairs to set as configuration properties.
     * @cat Plugins/autogrow
     */
	
	jQuery.autogrow = function (e, o)
	{
		this.options		  	= o || {};
		this.dummy			  	= null;
		this.interval	 	  	= null;
		this.line_height	  	= this.options.lineHeight || parseInt(jQuery(e).css('line-height'), 10);
		this.min_height		  	= this.options.minHeight || parseInt(jQuery(e).css('min-height'), 10);
		this.max_height		  	= this.options.maxHeight || parseInt(jQuery(e).css('max-height'), 10);
		this.textarea		  	= jQuery(e);
		
		if(isNaN(this.line_height )) {
		  this.line_height = 0;
		}
		// Only one textarea activated at a time, the one being used
		this.init();
	};
	
	jQuery.autogrow.fn = jQuery.autogrow.prototype = {
    autogrow: '1.2.2'
  };
	
 	jQuery.autogrow.fn.extend = jQuery.autogrow.extend = jQuery.extend;
	
	jQuery.autogrow.fn.extend({
						 
		init: function() {			
			var self = this;			
			this.textarea.css({overflow: 'hidden', display: 'block'});
			this.textarea.bind('focus', function() { self.startExpand(); } ).bind('blur', function() { self.stopExpand(); });
			this.checkExpand();	
		},
						 
		startExpand: function() {				
		  var self = this;
			this.interval = window.setInterval(function() {self.checkExpand(); }, 400);
		},
		
		stopExpand: function() {
			clearInterval(this.interval);	
		},
		
		checkExpand: function() {
			
			if (this.dummy == null)
			{
				this.dummy = jQuery('<div></div>');
				this.dummy.css({
												'font-size'     : this.textarea.css('font-size'),
												'font-family'   : this.textarea.css('font-family'),
												'width'         : this.textarea.css('width'),
												'padding-top'   : this.textarea.css('padding-top'),
												'padding-bottom': this.textarea.css('padding-bottom'),
												'padding-left'  : this.textarea.css('padding-left'),
												'padding-right' : this.textarea.css('padding-right'),
												'line-height'   : this.line_height + 'px',
												'overflow-x'    : 'hidden',
												'position'      : 'absolute',
												'top'           : 0,
												'left'		    : -9999
												}).appendTo('body');
			}
			
			// Strip HTML tags
			// var html = this.textarea.val().replace(/(<|>)/g, '');
			var html = this.textarea.val().replace(/</g, '&lt;').replace(/>/g, '&gt;');

			// IE is different, as per usual
			if (jQuery.browser.msie)
			{
				html = html.replace(/\n/g, '<BR>new');
			}
			else
			{
				html = html.replace(/\n/g, '<br>new');
			}
			
			if (this.dummy.html() != html ||  this.dummy.html().length === 0)
			{
				this.dummy.html(html);	
				
				if (this.max_height > 0 && (this.dummy.height() + this.line_height > this.max_height))
				{
					this.textarea.css('overflow-y', 'auto');
					this.textarea.css('height', this.max_height);	//Added this line to enfore the max height if content length more than max height.
				}
				else
				{
					this.textarea.css('overflow-y', 'hidden');
					if (this.textarea.height() < this.dummy.height() + this.line_height || (this.dummy.height() < this.textarea.height()))
					{	
						this.textarea.animate({height: (this.dummy.height() + this.line_height) + 'px'}, 100);	
					}
				}
			}
		}
						 
	 });
})(jQuery);