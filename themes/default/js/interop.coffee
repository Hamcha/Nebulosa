socket = io.connect 'http://'+location.host

socket.on 'networks', (data) -> window.interface.initNetworks data

socket.on 'message', (data) -> window.interface.addMessage data

socket.on 'notice', (data) -> window.interface.addNotice data

socket.on 'join', (data) -> window.interface.addChannelAction "join", data

socket.on 'part', (data) -> window.interface.addChannelAction "part", data

socket.on 'names', (data) -> window.interface.updateChannelInfo data

socket.on 'topic', (data) -> window.interface.setTopic data

window.interop =
	socket : socket