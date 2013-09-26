ClientProxy = Object.create null

ClientProxy.join = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.join data.channel

ClientProxy.part = (socket, data) ->
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.part data.channel

ClientProxy.message = (socket, data) ->
	return unless ircsrv.ircs[data.network]?
	message = { network:data.network, nickname:data.nickname, channel:data.channel, message:data.message, time:new Date() }
	ircsrv.pushBuffer data.network+"."+data.channel, "message", message
	ircsrv.ircs[data.network].client.say data.channel, data.message

ClientProxy.names = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.send "NAMES", data.channel

ClientProxy.topic = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.send "TOPIC", data.channel, data.topic

ClientProxy.quitirc = (socket, data) -> 
	return unless ircsrv.ircs[data.network]? and ircsrv.ircs[data.network].connected
	ircsrv.ircs[data.network].client.disconnect data.message
	ircsrv.ircs[data.network].connected = false
	socket.emit "disconnected", { network: data.network }

ClientProxy.quit = (socket, data) -> 
	# When the client exits the chat
	# TODO: Go away or something
	return

ClientProxy.connect = (socket, data) -> 
	return unless ircsrv.ircs[data.network]? and !ircsrv.ircs[data.network].connected
	ircsrv.ircs[data.network].client.connect()

ClientProxy.kick = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.send "KICK", data.channel, data.nick, data.message

ClientProxy.notice = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	message = { network:data.network, nickname:data.nickname, channel:data.channel, message:data.message, time:new Date() }
	ircsrv.pushBuffer data.network+"."+data.channel, "notice", message
	ircsrv.ircs[data.network].client.notice data.channel, data.message

ClientProxy.ping = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.notice data.channel, data.message

ClientProxy.nick = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	message = { network:data.network, oldnick:data.nickname, newnick:data.newnick, channels:data.channels, time:new Date() }
	ircsrv.ircs[data.network].client.send "NICK", data.newnick

ClientProxy.invite = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.send "INVITE", data.nickname, data.channel

ClientProxy.mode = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	if data.who? and data.who != ""
		ircsrv.ircs[data.network].client.send "MODE", data.channel, data.what.toString(), data.args
	else
		ircsrv.ircs[data.network].client.send "MODE", data.channel, data.what.toString()

ClientProxy.whois = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.send "WHOIS", data.nickname

ClientProxy.list = (socket, data) -> 
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.send "LIST"

ClientProxy.ctcp = (socket, data) ->
	# Drop them for now
	return

ClientProxy.chaninfo = (socket, data) ->
	return unless ircsrv.ircs[data.network]?
	socket.emit "chaninfo", { network:data.network, channeldata:ircsrv.chanInfo data.network, data.channel }

ClientProxy.netinfo = (socket, data) ->
	return unless ircsrv.ircs[data.network]?
	ircsrv.initClient socket

ClientProxy.raw = (socket, data) ->
	return unless ircsrv.ircs[data.network]?
	ircsrv.ircs[data.network].client.send.apply null, data.args

module.exports = ClientProxy