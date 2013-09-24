socket = undefined

createSocket = (user,pass) ->
	tryAuth = user? and pass?
	socket = io.connect 'http://'+location.host, { query: "user="+user+"&pass="+pass }
	socket.on 'error', (data) ->
		if data == "handshake unauthorized"
			window.interface.AuthError()
		else
			window.interface.Exception "Connection lost..", true

	socket.on 'networks', 	(data) -> window.interface.initNetworks data
	socket.on 'buffers', 	(flag) -> window.interface.bufferMode = flag
	socket.on 'message', 	(data) -> window.interface.addMessage data
	socket.on 'notice', 	(data) -> window.interface.addNotice data
	socket.on 'whois', 		(data) -> window.interface.addWhois data
	socket.on 'join', 		(data) -> window.interface.addChannelAction "join", data
	socket.on 'part', 		(data) -> window.interface.addChannelAction "part", data
	socket.on 'kick', 		(data) -> window.interface.addChannelAction "kick", data
	socket.on 'mode', 		(data) -> window.interface.addChannelAction "mode", data
	socket.on 'nick', 		(data) -> window.interface.addChannelAction "nick", data
	socket.on 'quit', 		(data) -> window.interface.addChannelAction "quit", data
	socket.on 'names', 		(data) -> window.interface.updateChannelUsers data
	socket.on 'chaninfo', 	(data) -> window.interface.updateChannelInfo data
	socket.on 'topic', 		(data) -> window.interface.setTopic data
	socket.on 'ircerror', 	(data) -> window.interface.addError data.message.args.join " "
	socket.on 'disconnected', (data) -> window.interface.addChannelAction "disconnected", data
	return socket

command = Object.create null

command.join = (net,chan,nick,args) ->
	return false unless args[0]?
	socket.emit "join", { network: net, channel: args[0] }

command.part = (net,chan,nick,args) ->
	# If the channel is not specified leave the current channel
	pchan = if args[0]? then args[0] else chan
	socket.emit "part", { network: net, channel: pchan }

command.nick = (net,chan,nick,args) ->
	return false unless args[0]?
	# Get all channels we're in
	chanlist = Object.keys window.interface.networks()[net].chans
	socket.emit "nick", { network: net, nickname: nick, newnick: args[0], channels: chanlist }

command.kick = (net,chan,nick,args) ->
	return false unless args[1]?
	reas = ifval args[2], args[1]
	socket.emit "kick", { network: net, nickname: nick, channel: args[0], nick:args[1], message:reas }

command.whois = (net,chan,nick,args) ->
	return false unless args[0]?
	socket.emit "whois", { network: net, nickname: args[0] }

command.quit = (net,chan,nick,args) ->
	quitmsg = ifval args[0], "Nebulosa IRC Client"
	socket.emit "quitirc", { network: net, message: quitmsg }

command.connect = (net,chan,nick,args) ->
	socket.emit "connect", { network: net }

command.msg = (net,chan,nick,args) ->
	return false if args.length < 2
	chan = args.splice 0,1
	msg = args.join " "
	socket.emit "message", { network: net, nickname: nick, channel: chan, message: msg }
	window.interface.addMessage { network: net, nickname: nick, channel: chan, message: msg, time: +new Date }

command.notice = (net,chan,nick,args) ->
	return false if args.length < 2
	chan = args.splice 0,1
	msg = args.join " "
	socket.emit "notice", { network: net, nickname: nick, channel: chan, message: msg }
	window.interface.addNotice { network: net, nickname: nick, channel: chan, message: msg, time: +new Date }

window.interop =
	createSocket : createSocket
	socket : socket
	command : command