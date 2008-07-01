/*
Copyright (c) 2006 Alexander MacCaw

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

var juggernaut;

var Juggernaut = Class.create({
  isConnected: false,

  initialize: function(options) {
    this.options = options;

    Event.observe(window, 'load', function() {
		    juggernaut = this;
		    this.setup();
		  }.bind(this)
		 );
  },

  initialized: function() {
    this.connect();
  },

  swf: function () {
    return $('flash_server');
  },

  connect: function() {
    this.swf().connect(this.options.host, this.options.port);
  },

  connected: function() {
    this.isConnected = true;
    this.sendData( $H({"broadcast":0,"channels":this.options.channels}).toJSON() );
  },

  sendData: function(data) {
    this.swf().sendData(escape(data));
  },

  errorConnecting: function() {
    Element.update('flash_message', 'Unable to connect to push server...');
    Element.show('flash');
  },

  disconnected: function () {
    Element.update('flash_message', 'Connection to push server lost. Please reload the page...');
    Element.show('flash');
  },

  receiveData: function (data) {
    var msg = unescape(data);
    eval(msg);
  },

  playSound: function(sound) {
    if(this.options.sounds) {
      this.swf().playSound(sound);
    }
  },

  setup: function() {

    var attributes = {
      id: "flash_server",
      name: "flash_server"
    };

    this.element = new Element('div', {id:'socket_server'});
    $(document.body).insert({bottom: this.element });

    swfobject.embedSWF("/socket_server.swf", "socket_server", "1", "1", "8,0,0,0", false, {}, {allowScriptAccess:"always"}, attributes);
  }


});

function checkConnection() {
  if( !juggernaut.isConnected ) {
    Element.update('flash_message', 'Unable to connect to push server, make sure flash is enabled for this site and SSL traffic is allowed...<br />You won\'t be able to see what others are saying.');
    Element.show('flash');
  }
}


