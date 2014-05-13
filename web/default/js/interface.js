/*jshint undef:true,unused:true,browser:true,devel:true*/
/*global Interface: true,makeCommand,socket*/

Interface = {

	servers : {},
	currentServerId  : "",
	currentChannelId : "",
	get currentServer() {
		return Interface.servers[Interface.currentServerId];
	},
	get currentChannel() {
		return Interface.currentServer.channels[Interface.currentChannelId];
	},
	get currentUserList() {
		return Interface.currentServer.users[Interface.currentChannelId];
	},

	init : function (serverList) {
		// Create click handler for channel boxes
		var onchange = function (server) {
			return function(cname) { Interface.switchTo(server, cname); };
		};

		// For every given server
		for (var server in serverList) {

			// Create server block
			var item = document.createElement("x-server-block");

			// Fill in the data
			item.serverName = serverList[server].ServerInfo.ServName;
			item.id = server;
			item.set(serverList[server]);
			item.onChannelClick = onchange(server);

			// Add it to the DOM
			document.getElementById("channels").appendChild(item);

			// Create the server object
			Interface.servers[server] = { "server":item, "channels": {}, "users": {} };

			// Fill in the channels
			for (var channel in serverList[server].Channels) {
				Interface.createChannel(server, channel);
				Interface.servers[server].users[channel].init(serverList[server].Channels[channel].Users);
			}
		}

		// Set default server and channel if available
		var servers = Object.keys(Interface.servers);
		if (servers.length > 0) {
			Interface.currentServerId = servers[0];
			var chans = Object.keys(Interface.currentServer.channels);
			if (chans.length > 0) {
				Interface.currentChannelId = chans[0];
				Interface.currentServer.server.select(Interface.currentChannelId);
				Interface.currentChannel.focus();
				Interface.currentUserList.focus();
			}
		}
	},

	addMessage : function (messageData) {
		// Ignore if the server doesn't exist (should never happen)
		if (!Interface.servers.hasOwnProperty(messageData.ServerId)) return;

		// Get affected server
		var server = Interface.servers[messageData.ServerId];

		// If the channel doesn't exist create it
		if (!server.channels.hasOwnProperty(messageData.Message.Target)) {
			Interface.createChannel(messageData.ServerId, messageData.Message.Target);
		}

		// Fill in the timestamp
		var d = new Date(messageData.DateTime * 1000);
		var time = [d.getHours(), d.getMinutes(), d.getSeconds()].map(function (e) {
				return ("0" + e).slice(-2);
		}).join(":");

		var target = "";

		switch (messageData.Message.Command) {
			// Chat message
			case "PRIVMSG":
				// Add chat message to its window
				var message = document.createElement("x-chat-message");
				// Check who wrote the last message (to hide nickname)
				var hide = false;
				var msgs = server.channels[messageData.Message.Target].messages;
				if (msgs.length > 0)
					hide = msgs[msgs.length - 1].username == messageData.Message.Source.Nickname;
				message.set(messageData.Message.Source.Nickname, messageData.Message.Text, time, hide);
				server.channels[messageData.Message.Target].addMessage(message);
				break;
			// Chat notice
			case "NOTICE":
				// Add notice to active window
				var notice = document.createElement("x-chat-notice");
				notice.set(messageData.Message.Source.Nickname, messageData.Message.Target, messageData.Message.Text, time);
				Interface.currentChannel.addMessage(notice);
				break;
			// Channel join
			case "JOIN":
				// Add join action to its window
				var join = document.createElement("x-chat-action");
				join.username  = messageData.Message.Source.Nickname;
				join.message   = "has joined the channel";
				join.timestamp = time;
				target = messageData.Message.Text !== "" ? messageData.Message.Text : messageData.Message.Target;
				server.channels[target].addMessage(join);
				break;
			// Channel part
			case "PART":
				// Add part action to its window
				var part = document.createElement("x-chat-action");
				part.username  = messageData.Message.Source.Nickname;
				part.message   = "has left the channel";
				part.timestamp = time;
				target = messageData.Message.Text !== "" ? messageData.Message.Text : messageData.Message.Target;
				server.channels[target].addMessage(part);
				break;
			// Topic change
			case "TOPIC":
				server.channels[messageData.Message.Target].setTopic(messageData.Message.Text,messageData.Message.Source);
				if (Interface.currentServerId  === messageData.ServerId &&
					Interface.currentChannelId === messageData.Message.Target) {
					document.getElementById("topic").innerHTML = server.channels[messageData.Message.Target].topic;
					if (server.channels[messageData.Message.Target].topic !== "")
						document.getElementById("topicBy").innerHTML = "set by " + server.channels[messageData.Message.Target].topicBy;
				}
				break;
		}
	},

	createChannel : function (sname, cname) {
		// Create channel box
		var channel = document.createElement("x-channel-box");
		document.getElementById("chatWrapper").appendChild(channel);

		// Create related userlist
		var userlist = document.createElement("x-user-list");
		document.getElementById("users").appendChild(userlist);

		// Assign to server object
		var server = Interface.servers[sname];
		server.channels[cname] = channel;
		server.users[cname] = userlist;
	},

	switchTo : function (sname, cname) {
		// Change server selection if changed
		if (Interface.currentServerId !== sname) {
			Interface.currentServer.server.deselect();
		}
		Interface.servers[sname].server.select(cname);

		// Change channel selection
		Interface.currentChannel.blur();
		Interface.servers[sname].channels[cname].focus();
		Interface.currentUserList.blur();
		Interface.servers[sname].users[cname].focus();

		// Change current server / channel value
		Interface.currentServerId  = sname;
		Interface.currentChannelId = cname;

		// Change topic if there is one
		document.getElementById("topic").innerHTML = Interface.servers[sname].channels[cname].topic;
		if (Interface.servers[sname].channels[cname].topic !== "")
			document.getElementById("topicBy").innerHTML = "set by " + Interface.servers[sname].channels[cname].topicBy;
	},

	onKey : function (event) {
		var text = document.getElementById("messageBox").value;
		var out = {};
		switch (event.keyCode) {
			case 13: // Pressed ENTER
				event.preventDefault();
				if (text.length > 1 && text[0] == "/" && text[1] != "/") {
					out = makeCommand(text);
				} else {
					out = {
						"Source" : {
							"Nickname" : Interface.currentServer.server.info.Nickname,
							"Username" : Interface.currentServer.server.info.Username
						},
						"Command":"PRIVMSG",
						"Target" : Interface.currentChannelId,
						"Text"   : text.replace(/^\/\//,"/")
					};
				}
				socket.emit("command",Interface.currentServerId,out);
				document.getElementById("messageBox").value = "";
				break;
		}
	}
};