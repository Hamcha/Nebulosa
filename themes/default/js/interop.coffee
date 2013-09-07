socket = io.connect 'http://'+location.host

socket.on 'networks', (data) -> window.interface.initNetworks data

socket.on 'buffers', (flag) -> window.interface.bufferMode = flag

socket.on 'message', (data) -> window.interface.addMessage data

socket.on 'notice', (data) -> window.interface.addNotice data

socket.on 'join', (data) -> window.interface.addChannelAction "join", data

socket.on 'part', (data) -> window.interface.addChannelAction "part", data

socket.on 'names', (data) -> window.interface.updateChannelUsers data

socket.on 'chaninfo', (data) -> window.interface.updateChannelInfo data

socket.on 'topic', (data) -> window.interface.setTopic data

command = Object.create null

command.join = (net,chan,nick,args) ->
	return false unless args[0]?
	socket.emit "join", { network: net, channel: args[0] }

command.part = (net,chan,nick,args) ->
	# If the channel is not specified leave the current channel
	pchan = if args[0]? then args[0] else chan
	socket.emit "part", { network: net, channel: pchan }

window.interop =
	socket : socket
	command : command