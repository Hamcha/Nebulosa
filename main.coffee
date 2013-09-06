global.config 	= require "./config"
global.http 	= require "http"
global.fs 		= require "fs"
global.socketio	= require "socket.io"
global.proxy	= require "event-proxy"
global.connect 	= require "connect"
global.irc		= require "irc"
global.ircsrv	= require "./chat"
global.buffer   = require "./buffer"

# Fallback if selected theme doesn't exist
if not fs.existsSync "themes/"+config.webconf.theme
	console.log "Custom theme \""+config.webconf.theme+"\" doesn't exist, falling back to \"default\""
	config.webconf.theme = "default"

# Setup static directory serving
web = connect().use connect.static "themes/"+config.webconf.theme

# Create webserver and bind port
wsrv = http.createServer web
wsrv.listen config.webconf.bindport
# Setup Socket.IO for listening
global.io = socketio.listen wsrv, { log: false }
# Start IRC Client
ircsrv.start()

io.sockets.on 'connection', (socket) ->
	ircsrv.initClient socket
	ircsrv.sendBuffers socket
	# Proxy all events to the ClientProxy
	proxy ClientProxy, clientMap, socket, socket
	return

console.log "Webserver listening @ port " + config.webconf.bindport