socket = undefined

createSocket = (user,pass) ->
	document.cookie = "user="+user
	document.cookie = "pass="+pass
	socket = io.connect 'http://'+location.host
	socket.on 'error', (data) ->
		if data == "handshake unauthorized"
			# Expire both cookies
			document.cookie = "user=; expires=Thu, 01 Jan 1970 00:00:01 GMT;"
			document.cookie = "pass=; expires=Thu, 01 Jan 1970 00:00:01 GMT;"
			window.interface.AuthError()
		else
			window.interface.Exception "Connection has been lost..", true

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
	interop.socket = socket

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
	return false if args.length < 2
	chan = args.splice 0,1
	who = args.splice 0,1
	reas = ifval args.join " ", who
	socket.emit "kick", { network: net, nickname: nick, channel:chan.toString(), nick:who.toString(), message:reas }

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
	socket.emit "message", { network: net, nickname: nick, channel: chan.toString(), message: msg }
	window.interface.messageBar ""
	window.interface.addMessage { network: net, nickname: nick, channel: chan.toString(), message: msg, time: +new Date }

command.notice = (net,chan,nick,args) ->
	return false if args.length < 2
	chan = args.splice 0,1
	msg = args.join " "
	socket.emit "notice", { network: net, nickname: nick, channel: chan.toString(), message: msg }
	window.interface.addNotice { network: net, nickname: nick, channel: chan.toString(), message: msg, time: +new Date }
	window.interface.messageBar ""

command.topic = (net,chan,nick,args) ->
	return false if args.length < 2
	chan = args.splice 0,1
	msg = args.join " "
	socket.emit "topic", { network: net, nickname: nick, channel: chan.toString(), topic: msg }

command.mode = (net,chan,nick,args) ->
	return false if args.length < 2
	chan = args.splice 0,1
	what = args.splice 0,1
	who = args.join " " if args.length > 0
	socket.emit "mode", { network: net, nickname: nick, channel: chan.toString(), what:what, who:who }

command.raw = (net,chan,nick,args) ->
	return false if args.length < 1
	socket.emit "raw", { network: net, args:args }

window.interop =
	createSocket : createSocket
	socket : socket
	command : command