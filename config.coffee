## Configuration file for Nebulosa ##

# Ignore this, it's coffeescript stuff
servers = Object.create null

## EDIT 'FROM' HERE

# Webserver configuration

webserver = 
	bindport : 8033 		# Which port to bind
	localhostonly : false 	# Set true only if you want to disable remote access
	password : "something"  # Password, if you have remote access enabled
							# it will prevent other people from accessing
							# your IRC session
	theme : "default"		# Choose theme for the interface

# Servers configuration

### Example server (use as template)

servers.template = 
	name     : "Example server"
	address  : "irc.example.com:6667"	# Optional :PORT (default 6667)
	nickname : "mynick"					# Default nickname 
	altnick  : "mynick????"				# Alternate nickname (? means random number)
	realname : "My real name here"		# Real name
	# Channels to join when connected
	autojoin : [ "#example", "#coders" ]

###

servers.ponychat = 
	name     : "Ponychat"
	address  : "irc.ponychat.net"	# Optional :PORT (default 6667)
	nickname : "twalot"				# Default nickname 
	altnick  : "twalot????"			# Alternate nickname (? means random number)
	realname : "flotrshi sistah"	# Real name
	# Channels to join when connected
	autojoin : [ "#testbass", "#brony.it" ]

## DON'T EDIT BELOW THIS POINT (or things will turn ugly)

svalues = s for s of servers
module.exports =
	servers : svalues
	webconf : webserver
	