// setTimeout will not be called untilled the DOM is loaded
setTimeout(function() {
	var ifr = document.createElement('iframe');
	ifr.src = '/tuneup/sandbox';
	
	var style        = ifr.style;
	style.visibility = 'hidden';
	style.width      = '0';
	style.height     = '0';
	
	document.body.appendChild(ifr);
}, 50);