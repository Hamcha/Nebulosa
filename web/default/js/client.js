/*jshint undef:true,unused:true,browser:true,devel:true*/
/*global io,Interface,socket:true*/

window.addEventListener('polymer-ready', function() {

	socket = io.connect();

	socket.on("irc", function (message) {
        Interface.addMessage(message);
	});

	socket.on("greet", function (greetData) {
        Interface.init(greetData);
	});

});