EventProxy = Object.create null

EventProxy.join = (ircc,chan,nick) -> 
	io.sockets.emit 'join', { network:ircc.name, channel:chan, nickname:nick }

EventProxy.part = (ircc,chan,nick,reas) -> 
	io.sockets.emit 'part', { network:ircc.name, channel:chan, nickname:nick, reason:reas }

EventProxy.message = (ircc,nick,t,msg) ->
	io.sockets.emit 'message', { network:ircc.name, nickname:nick, to:t, message:msg }

EventProxy.names = (ircc,chan,nickl) -> 
	io.sockets.emit 'names', { network:ircc.name, channel:chan, nicks:nickl }

EventProxy.topic = (ircc,chan,txt,nick) -> 
	io.sockets.emit 'topic', { network:ircc.name, channel:chan, nickname:nick, topic:txt }

EventProxy.quit = (ircc,nick,reas,chan) -> 
	io.sockets.emit 'quit', { network:ircc.name, channels:chan, nickname:nick, reason:reas }

EventProxy.kick = (ircc,chan,nick,b,reas) -> 
	io.sockets.emit 'kick', { network:ircc.name, channel:chan, nickname:nick, by:b, reason:reas }

EventProxy.kill = (ircc,nick,reas,chan) -> 
	io.sockets.emit 'kill', { network:ircc.name, channels:chan, nickname:nick, reason:reas }

EventProxy.notice = (ircc,nick,to,msg) -> 
	io.sockets.emit 'notice', { network:ircc.name, nickname:nick, to:to, message:msg }

EventProxy.ping = (ircc,s) -> 
	io.sockets.emit 'ping', { network:ircc.name, server:s }

EventProxy.nick = (ircc,an,nn,chan) -> 
	io.sockets.emit 'nick', { network:ircc.name, oldnick:an, newnick:nn, channels:chan }

EventProxy.invite = (ircc,chan,f) -> 
	io.sockets.emit 'invite', { network:ircc.name, channel:chan, from:f }

EventProxy.modep = (ircc,chan,b,m,arg) -> 
	io.sockets.emit 'mode', { network:ircc.name, what:"+", channel:chan, by:b, mode:m, argument:arg }

EventProxy.modem = (ircc,chan,b,m,arg) -> 
	io.sockets.emit 'mode', { network:ircc.name, what:"-", channel:chan, by:b, mode:m, argument:arg }

EventProxy.whois = (ircc,data) -> 
	io.sockets.emit 'whois', { network:ircc.name, info:data }

EventProxy.error = (ircc,err) -> 
	io.sockets.emit 'error', { network:ircc.name, message:err }

EventProxy.list = (ircc,clist) -> 
	io.sockets.emit 'list', { network:ircc.name, list:clist }

EventProxy.ctcp = (ircc,f,t,m,p) -> 
	ChatClient.ctcp(ircc,f,t,m,p)
	io.sockets.emit 'ctcp', { network:ircc.name, from:f, to:t, text:m, type:p }

module.exports = EventProxy