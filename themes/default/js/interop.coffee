socket = io.connect 'http://'+location.host

###
On Network data (Startup)
###
socket.on 'networks', (data) ->
	window.interface.initNetworks data

###
On Network data (Startup)
###
socket.on 'self', (data) ->
	window.interface.nickname data.nickname

###
On IRC Message
###
socket.on 'message', (data) ->
	window.interface.addMessage data

window.interop =
	socket : socket