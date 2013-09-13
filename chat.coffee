ChatClient = Object.create null
global.EventProxy = require("./eproxy")
global.ClientProxy = require("./cproxy")
global.buffers = Object.create null

ChatClient.start = () ->
	ChatClient.ircs = Object.create null
	for i,s of config.servers
		ircClient = Object.create null
		# Setup basic informations
		ircClient.name = i
		ircClient.displayName = s.name
		ircClient.connected = false
		ircClient.client = new irc.Client s.address, s.nickname, { channels:s.autojoin, realName:s.realname, userName:"nebulosa" }
		# Proxy all events to the EventProxy
		proxy EventProxy, eventMap, ircClient.client, ircClient
		# Put it into the list
		ChatClient.ircs[i] = ircClient
	return

ChatClient.ctcp = (server, from, to, text, type) ->
	# Drop all CTCP for the moment
	return

ChatClient.initClient = (socket) ->
	# Send all network and channels data (including names, if possible)
	networks = {}
	for i,s of ChatClient.ircs
		networks[i] =
			nickname: s.client.nick
			name: s.displayName
			chans: s.client.chans
	socket.emit "networks", networks
	return

ChatClient.sendBuffers = (socket) ->
	# Activate buffer mode (special flag)
	socket.emit "buffers", true
	for j,c of buffers
		bufItem = c.get()
		socket.emit x.type, x.data for x in bufItem
	# Disable buffer mode
	socket.emit "buffers", false
	return

ChatClient.chanInfo = (net, chan) ->
	return if ChatClient.ircs[net].client.chans? then ChatClient.ircs[net].client.chans[chan] else undefined

ChatClient.pushBuffer = (bufferName, what, data) ->
	if !buffers[bufferName]?
		buffers[bufferName] = new buffer config.bufferSize
	buffers[bufferName].push {type:what, data:data}

global.eventMap =
	'join' 		: 'join'
	'part' 		: 'part'
	'message' 	: 'message'
	'names'		: 'names'
	'topic'		: 'topic'
	'quit'		: 'quit'
	'kick'		: 'kick'
	'kill'		: 'kill'
	'notice'	: 'notice'
	'ping'		: 'ping'
	'ctcp'		: 'ctcp'
	'nick'		: 'nick'
	'invite'	: 'invite'
	'+mode' 	: 'modep'
	'-mode' 	: 'modem'
	'whois' 	: 'whois'
	'error'		: 'error'
	'registered':'registered'
	'channellist' : 'list'

global.clientMap =
	'join' 		: 'join'
	'part' 		: 'part'
	'message' 	: 'message'
	'names'		: 'names'
	'topic'		: 'topic'
	'quitirc'	: 'quitirc'
	'kick'		: 'kick'
	'notice'	: 'notice'
	'ping'		: 'ping'
	'ctcp'		: 'ctcp'
	'nick'		: 'nick'
	'invite'	: 'invite'
	'mode' 		: 'mode'
	'whois' 	: 'whois'
	'list' 		: 'list'
	'chaninfo'	: 'chaninfo'
	'netinfo'	: 'netinfo'
	'raw'		: 'raw'
	'disconnect': 'quit'
	'connect'	: 'connect'
	'quit'		: 'quit'

module.exports = ChatClient