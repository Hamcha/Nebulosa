socket = io.connect 'http://'+location.host

#  On Network data (Startup)
socket.on 'networks', (data) -> window.interface.initNetworks data

# On IRC Message
socket.on 'message', (data) -> window.interface.addMessage data

# On IRC Notice
socket.on 'notice', (data) -> window.interface.addNotice data

# On IRC Join
socket.on 'join', (data) -> window.interface.addChannelAction "join", data

# On IRC Part
socket.on 'part', (data) -> window.interface.addChannelAction "part", data

window.interop =
	socket : socket