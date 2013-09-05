socket = io.connect 'http://'+location.host

###
On Network data (Startup)
###
socket.on 'networks', (data) ->
	window.interface.initNetworks data

###
On IRC Message
###
socket.on 'message', (data) ->
	console.log data
	window.interface.addMessage data