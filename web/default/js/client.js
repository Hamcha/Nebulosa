/*jshint undef:true,unused:true,browser:true,devel:true*/
/*global io,Interface,socket:true*/

window.addEventListener('polymer-ready', function() {

	window.socket = io.connect();

	socket.on("irc", function (message) {
		handleIRC(message);
	});

	socket.on("greet", function (greetData) {
        Interface.init(greetData);
	});

	socket.on("buffer", function (bufdata) {
		for (var i = 0; i < bufdata.length; i++) {
			handleIRC(bufdata[i]);
		}
	});
});

var handleIRC = function (message) {
	if (message.Message.Command === "PRIVMSG" ||
		message.Message.Command === "NOTICE"  ||
		message.Message.Command === "JOIN"    ||
		message.Message.Command === "PART"    ||
		message.Message.Command === "QUIT"    ||
		message.Message.Command === "TOPIC") {
		return Interface.addMessage(message);
	}
	console.log(message);
};