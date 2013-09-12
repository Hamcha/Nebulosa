EventProxy = Object.create null

EventProxy.join = (ircc,chan,nick) -> 
	message = { network:ircc.name, channel:chan, nickname:nick, time:new Date() }
	ircsrv.pushBuffer ircc.name+"."+chan, "join", message
	io.sockets.emit 'join', message

EventProxy.part = (ircc,chan,nick,reas) -> 
	message = { network:ircc.name, channel:chan, nickname:nick, reason:reas, time:new Date() }
	ircsrv.pushBuffer ircc.name+"."+chan, "part", message
	io.sockets.emit 'part', message

EventProxy.message = (ircc,nick,chan,msg) ->
	message = { network:ircc.name, nickname:nick, channel:chan, message:msg, time:new Date() }
	# Is query message?
	if chan == ircc.client.nick
		ircsrv.pushBuffer ircc.name+"."+nick, "message", message
	else
		ircsrv.pushBuffer ircc.name+"."+chan, "message", message
	io.sockets.emit 'message', message

EventProxy.names = (ircc,chan,nickl) -> 
	io.sockets.emit 'names', { network:ircc.name, channel:chan, nicks:nickl, time:new Date() }

EventProxy.topic = (ircc,chan,txt,nick) -> 
	message = { network:ircc.name, channel:chan, nickname:nick, topic:txt, time:new Date() }
	ircsrv.pushBuffer ircc.name+"."+chan, "topic", message
	io.sockets.emit 'topic', message

EventProxy.quit = (ircc,nick,reas,chan) -> 
	message = { network:ircc.name, channels:chan, nickname:nick, reason:reas, time:new Date() }
	io.sockets.emit 'quit', message
	ircsrv.pushBuffer ircc.name+"."+ch, "quit", { network:ircc.name, channels:ch, nickname:nick, reason:reas, time:new Date() } for ch in chan

EventProxy.kick = (ircc,chan,nick,b,reas) -> 
	message = { network:ircc.name, channel:chan, nickname:nick, by:b, reason:reas, time:new Date() }
	ircsrv.pushBuffer ircc.name+"."+chan, "kick", message
	io.sockets.emit 'kick', message

EventProxy.kill = (ircc,nick,reas,chan) -> 
	io.sockets.emit 'kill', { network:ircc.name, channels:chan, nickname:nick, reason:reas, time:new Date() }

EventProxy.notice = (ircc,nick,chan,msg) -> 
	message = { network:ircc.name, nickname:nick, channel:chan, message:msg, time:new Date() }
	ircsrv.pushBuffer ircc.name+"."+chan, "notice", message
	io.sockets.emit 'notice', message

EventProxy.ping = (ircc,s) -> 
	io.sockets.emit 'ping', { network:ircc.name, server:s, time:new Date() }

EventProxy.nick = (ircc,an,nn,chan) -> 
	message = { network:ircc.name, oldnick:an, newnick:nn, channels:chan, time:new Date() }
	io.sockets.emit 'nick', message
	# I could've just used MESSAGE, right? No, because Javascript is stupid.
	ircsrv.pushBuffer ircc.name+"."+ch, "nick", { network:ircc.name, oldnick:an, newnick:nn, channels:ch, time:new Date() } for ch in chan

EventProxy.invite = (ircc,chan,f) -> 
	io.sockets.emit 'invite', { network:ircc.name, channel:chan, from:f, time:new Date() }

EventProxy.modep = (ircc,chan,b,m,arg) -> 
	message = { network:ircc.name, what:"+", channel:chan, by:b, mode:m, argument:arg, time:new Date() }
	ircsrv.pushBuffer ircc.name+"."+chan, "mode", message
	io.sockets.emit 'mode', message

EventProxy.modem = (ircc,chan,b,m,arg) ->
	message = { network:ircc.name, what:"-", channel:chan, by:b, mode:m, argument:arg, time:new Date() }
	ircsrv.pushBuffer ircc.name+"."+chan, "mode", message 
	io.sockets.emit 'mode', message

EventProxy.whois = (ircc,data) -> 
	io.sockets.emit 'whois', { network:ircc.name, info:data, time:new Date() }

EventProxy.error = (ircc,err) -> 
	io.sockets.emit 'error', { network:ircc.name, message:err }

EventProxy.list = (ircc,clist) -> 
	io.sockets.emit 'list', { network:ircc.name, list:clist }

EventProxy.ctcp = (ircc,f,t,m,p) -> 
	ircsrv.ctcp(ircc,f,t,m,p)
	io.sockets.emit 'ctcp', { network:ircc.name, from:f, to:t, text:m, type:p }

EventProxy.registered = (ircc) -> 
	ircc.connected = true

module.exports = EventProxy