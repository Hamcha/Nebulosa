EventProxy = Object.create null

EventProxy.join = (ircc,chan,nick) -> 
	message = { network:ircc.name, channel:chan, nickname:nick }
	ircsrv.pushBuffer ircc.name+"."+chan, "join", message
	io.sockets.emit 'join', message

EventProxy.part = (ircc,chan,nick,reas) -> 
	message = { network:ircc.name, channel:chan, nickname:nick, reason:reas }
	ircsrv.pushBuffer ircc.name+"."+chan, "part", message
	io.sockets.emit 'part', message

EventProxy.message = (ircc,nick,chan,msg) ->
	message = { network:ircc.name, nickname:nick, channel:chan, message:msg }
	ircsrv.pushBuffer ircc.name+"."+chan, "message", message
	io.sockets.emit 'message', message

EventProxy.names = (ircc,chan,nickl) -> 
	io.sockets.emit 'names', { network:ircc.name, channel:chan, nicks:nickl }

EventProxy.topic = (ircc,chan,txt,nick) -> 
	message = { network:ircc.name, channel:chan, nickname:nick, topic:txt }
	ircsrv.pushBuffer ircc.name+"."+chan, "topic", message
	io.sockets.emit 'topic', message

EventProxy.quit = (ircc,nick,reas,chan) -> 
	message = { network:ircc.name, channels:chan, nickname:nick, reason:reas }
	ircsrv.pushBuffer ircc.name+"."+chan, "quit", message
	io.sockets.emit 'quit', message

EventProxy.kick = (ircc,chan,nick,b,reas) -> 
	message = { network:ircc.name, channel:chan, nickname:nick, by:b, reason:reas }
	ircsrv.pushBuffer ircc.name+"."+chan, "kick", message
	io.sockets.emit 'kick', message

EventProxy.kill = (ircc,nick,reas,chan) -> 
	io.sockets.emit 'kill', { network:ircc.name, channels:chan, nickname:nick, reason:reas }

EventProxy.notice = (ircc,nick,chan,msg) -> 
	message = { network:ircc.name, nickname:nick, channel:chan, message:msg }
	ircsrv.pushBuffer ircc.name+"."+chan, "notice", message
	io.sockets.emit 'notice', message

EventProxy.ping = (ircc,s) -> 
	io.sockets.emit 'ping', { network:ircc.name, server:s }

EventProxy.nick = (ircc,an,nn,chan) -> 
	message = { network:ircc.name, oldnick:an, newnick:nn, channels:chan }
	ircsrv.pushBuffer ircc.name+"."+chan, "nick", message
	io.sockets.emit 'nick', message

EventProxy.invite = (ircc,chan,f) -> 
	io.sockets.emit 'invite', { network:ircc.name, channel:chan, from:f }

EventProxy.modep = (ircc,chan,b,m,arg) -> 
	message = { network:ircc.name, what:"+", channel:chan, by:b, mode:m, argument:arg }
	ircsrv.pushBuffer ircc.name+"."+chan, "mode", message
	io.sockets.emit 'mode', message

EventProxy.modem = (ircc,chan,b,m,arg) ->
	message = { network:ircc.name, what:"-", channel:chan, by:b, mode:m, argument:arg }
	ircsrv.pushBuffer ircc.name+"."+chan, "mode", message 
	io.sockets.emit 'mode', message

EventProxy.whois = (ircc,data) -> 
	io.sockets.emit 'whois', { network:ircc.name, info:data }

EventProxy.error = (ircc,err) -> 
	io.sockets.emit 'error', { network:ircc.name, message:err }

EventProxy.list = (ircc,clist) -> 
	io.sockets.emit 'list', { network:ircc.name, list:clist }

EventProxy.ctcp = (ircc,f,t,m,p) -> 
	ircsrv.ctcp(ircc,f,t,m,p)
	io.sockets.emit 'ctcp', { network:ircc.name, from:f, to:t, text:m, type:p }

module.exports = EventProxy