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

global.useAuth = config.webconf.username isnt "" and config.webconf.password isnt ""

web = connect().use connect.static "themes/"+config.webconf.theme
web.use (req,res) -> if req.url is "/useAuth" then res.end useAuth.toString() else res.end()
# Create webserver and bind port
wsrv = http.createServer web
wsrv.listen config.webconf.bindport
# Setup Socket.IO for listening
global.io = socketio.listen wsrv, { log: false }

if useAuth
	io.set 'authorization', (handshakeData, cb) ->
		if handshakeData.query.user? and handshakeData.query.user is config.webconf.username and handshakeData.query.pass? and  handshakeData.query.pass is config.webconf.password
			return cb null, true
		cb null, false
# Start IRC Client
ircsrv.start()

io.sockets.on 'connection', (socket) ->
	ircsrv.initClient socket
	ircsrv.sendBuffers socket
	# Proxy all events to the ClientProxy
	proxy ClientProxy, clientMap, socket, socket
	return

console.log "Webserver listening @ port " + config.webconf.bindport