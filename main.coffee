global.config 	= require "./config"
global.http 	= require "http"
global.fs 		= require "fs"
global.io 		= require "socket.io"
global.connect 	= require "connect"

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
io.listen wsrv, { log: false }

console.log "Webserver listening @ port " + config.webconf.bindport