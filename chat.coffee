ChatClient = Object.create null
global.EventProxy = require("./eproxy")
global.ClientProxy = require("./cproxy")

ChatClient.start = () ->
	ChatClient.ircs = Object.create null
	for i,s of config.servers
		ircClient = Object.create null
		# Setup basic informations
		ircClient.name = s.name
		ircClient.client = new irc.Client s.address, s.nickname, { channels:s.autojoin, realName:s.realname }
		# Proxy all events to the EventProxy
		proxy EventProxy, eventMap, ircClient.client, ircClient.client
		# Put it into the list
		ChatClient.ircs[i] = ircClient
	return

ChatClient.ctcp = (server, from, to, text, type) ->
	# Drop all CTCP for the moment
	return

ChatClient.initClient = (socket) ->
	socket.emit "networks", {}
	# Send all network and channels data (including names, if possible)
	return

ChatClient.sendBuffers = (socket) ->
	# Send last N messages per channel
	return


eventMap =
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
	'channellist' : 'list'

module.exports = ChatClient