var _window   = window.parent,    // window obj of the main page
    _document = _window.document, // document obj of the main page
    TuneUp    = _window.TuneUp;   // TuneUp obj from declared on main page

var _$ = $; // rename Protoype bling
// our new bling will reference our main window then call Prototype bling
$ = function(element) {
	if(typeof element == 'string') {
		element = _document.getElementById(element);
	}
	
	return _$(element);
};

var _$$ = $$;  // rename Protoype double  bling
// our new double bling will reference our main window then call Prototype bling
$$ = function() {
  return Selector.findChildElements(_document, $A(arguments));
}

// ensures that Prototypes Element.extend actually exstend another frames node
_nativeExtensions = false;

_window.TuneUpSandbox = window;


TuneUp.switchSchema = function(table) {
  var element = $('tuneup-schema-table-' + table);
  var operation = element.visible() ? 'hide' : 'show';
  $$('#tuneup-schema .tuneup-schema-table').each(function(s) { s.hide(); })
  element[operation]();
  $('tuneup-schema')[operation]();
}
TuneUp.Spinner = {
  start: function() { $('tuneup_spinner').show(); },
  stop: function() { $('tuneup_spinner').hide(); }
}

TuneUp.adjustElement = function(e) {
	var top = parseFloat(Element.getStyle(e, 'top') || 0);
	var adjust = 0;

	if ($('tuneup-flash').hasClassName('tuneup-show')) {
		if (!e.hasClassName('tuneup-flash-adjusted')) {
			adjust = 27;
			e.addClassName('tuneup-flash-adjusted');
		}
	}
	else {
		if (e.hasClassName('tuneup-flash-adjusted')) {
			adjust = -27;
			e.removeClassName('tuneup-flash-adjusted');
		}
	}
	
	if (e.hasClassName('tuneup-adjusted'))
		e.style.top = (top + adjust) + 'px';
	else {
		e.style.top = (top + 50 + adjust) + 'px';
		e.addClassName('tuneup-adjusted')
	}
}

TuneUp.adjustFixedElements = function(e) {
	$(_document.body).descendants().each(function(e) {
		var pos = Element.getStyle(e, 'position');
		if (pos == 'fixed') {
			TuneUp.adjustElement(e);
		}
	});
}

TuneUp.adjustAbsoluteElements = function(e) {
	$(e).immediateDescendants().each(function (e) {
		if (e.id == "tuneup") {
			return;
		}
		var pos = Element.getStyle(e, 'position');
		if (pos == 'absolute') {
			TuneUp.adjustElement(e);
			TuneUp.adjustAbsoluteElements(e);
		}
		else if (pos == 'relative') {
			// do nothing
		}
		else {
			TuneUp.adjustAbsoluteElements(e);
		}
	});
}

Event.observe(window, 'load', function() {
  new Insertion.Top(_document.body, "<div id='tuneup'><h1>FiveRuns TuneUp</h1><img id='tuneup_spinner' style='display:none' src='/images/tuneup/spinner.gif' alt=''/><div id='tuneup-content' style='display:block'></div></div><div id='tuneup-flash'></div>");
  
	TuneUp.adjustAbsoluteElements(_document.body);
	TuneUp.adjustFixedElements();

	new Ajax.Request('/tuneup?uri=' + encodeURIComponent(_document.location.href), {
      asynchronous : true,
      evalScripts  : true,
      onLoading    : TuneUp.Spinner.start,
      onComplete   : TuneUp.Spinner.stop
    });
});


