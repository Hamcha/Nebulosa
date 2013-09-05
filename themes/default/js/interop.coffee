socket = io.connect 'http://'+location.host

socket.on 'message', (data) ->
	console.log data