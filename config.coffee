## Configuration file for Nebulosa ##

# Ignore this, it's coffeescript stuff
servers = Object.create null

## EDIT 'FROM' HERE

# General configuration

general =
	bufferSize : 20 	# How many messages do you want to memorize

# Webserver configuration

webserver = 
	bindport : 8000 		# Which port to bind
	localhostonly : false 	# Set true only if you want to disable remote access
	username : ""			# Username, read below for more information
	password : ""			# Password, if you have remote access enabled
							# it will prevent other people from accessing your IRC session
							# If you want to disable it put a blank string ("") on both
	theme : "default"		# Theme for the web interface

# Servers configuration

### Example server (use as template)

servers.template = 
	name     : "Example server"
	address  : "irc.example.com"
	nickname : "mynick"					# Default nickname
	awaynick : ""					 # Nickname when offline
	realname : "My real name here"		# Real name
	# Channels to join when connected
	autojoin : [ "#example", "#coders" ]

###

servers.ponychat = 
	name     : "Ponychat"
	address  : "irc.ponychat.net"
	nickname : "nebulosa"			 # Default nickname
	awaynick : "nebu`OFF"			 # Nickname when offline
	realname : "Nebulosa IRC Client" # Real name
	# Channels to join when connected
	autojoin : [ "#testbass", "#testbass2" ]

servers.rizon = 
	name     : "Rizon"
	address  : "irc.rizon.net"
	nickname : "nebulosa"			 # Default nickname
	awaynick : "nebu`OFF"			 # Nickname when offline
	realname : "Nebulosa IRC Client" # Real name
	# Channels to join when connected
	autojoin : [ "#brls" ]

## DON'T EDIT BELOW THIS POINT (or things will turn ugly)

module.exports =
	servers : servers
	webconf : webserver

module.exports[x] = y for x,y of general