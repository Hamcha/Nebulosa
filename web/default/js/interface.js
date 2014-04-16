/*jshint undef:true,unused:true,browser:true,devel:true*/
/*global Interface: true*/

Interface = {

    servers : {},
    currentServer  : "",
    currentChannel : "",

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
            Interface.servers[server] = { "server":item, "channels": {} };
            // Fill in the channels
            for (var channel in serverList[server].Channels) {
                Interface.createChannel(server, channel);
            }
        }
        // Set default server and channel if available
        var servers = Object.keys(Interface.servers);
        if (servers.length > 0) {
            Interface.currentServer = servers[0];
            var chans = Object.keys(Interface.servers[Interface.currentServer].channels);
            if (chans.length > 0) {
                Interface.currentChannel = chans[0];
                Interface.servers[Interface.currentServer].server.select(Interface.currentChannel);
                Interface.servers[Interface.currentServer].channels[Interface.currentChannel].focus();
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
        // Create a new chat message
        var message = document.createElement("x-chat-message");
        // Fill in the timestamp
        var d = new Date(messageData.DateTime * 1000);
        var time = [d.getHours(), d.getMinutes(), d.getSeconds()].map(function (e) {
                return ("0" + e).slice(-2);
        }).join(":");
        // Set message data
        message.set(messageData.Message.Source.Nickname, messageData.Message.Text, time);
        // Add it to its channel window
        server.channels[messageData.Message.Target].addMessage(message);
    },

    createChannel : function (sname, cname) {
        var server  = Interface.servers[sname];
        var channel = document.createElement("x-channel-box");
        document.getElementById("chatWrapper").appendChild(channel);
        server.channels[cname] = channel;
    },

    switchTo : function (sname, cname) {
        // Change server selection if changed
        if (Interface.currentServer != sname) {
            Interface.servers[Interface.currentServer].server.deselect();
        }
        Interface.servers[sname].server.select(cname);
        // Change channel selection
        Interface.servers[Interface.currentServer].channels[Interface.currentChannel].blur();
        Interface.servers[sname].channels[cname].focus();
        // Change current server / channel value
        Interface.currentServer  = sname;
        Interface.currentChannel = cname;
    }
};