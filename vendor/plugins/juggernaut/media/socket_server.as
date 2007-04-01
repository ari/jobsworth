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

function connect() {
     // Create new XMLSocket object
	 System.security.loadPolicyFile(crossdomain);
	 socket = new XMLSocket();
	 socket.connect(host, port);
	 socket.onXML = newXML;
     socket.onConnect = newConnection;
     socket.onClose = endConnection;
        }
		
        function newConnection (success) {
            if (success) {
				socket.send('{"broadcast":0,"channels":[' + unescape(juggernaut_data) + ']}');
				socket.send("\n");
                getURL("javascript:flashConnected()");
            }
            else {
                getURL("javascript:flashErrorConnecting()");
            }
        }

        function endConnection () {
            getURL("javascript:flashConnectionLost()");
        }

        function newXML (input) {
            // convert XML object to string and send
            fscommand("send_var", input.toString());
			
			//getURL("javascript:flashData('" + input.toString() + "')"); //Old - doesn't work over 500 chars in IE
        }
		
		connect();