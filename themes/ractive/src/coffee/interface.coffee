Channel = (cdata) ->
	this.created = cdata.created
	this.key = cdata.key
	this.isquery = false
	this.unread = 0
	this.mentioned = false
	this.serverName = cdata.serverName
	this.mode = cdata.mode
	this.topic = cdata.topic if cdata.topic?
	this.topicBy = cdata.topicBy if cdata.topicBy?
	return

User = (nick,val) ->
	this.nick = nick
	this.val = val
	return

Interface = Ractive.extend
	data :
		networks : {}
		currentNetwork : ""
		currentChannel : ""
		userlist : {}
		messages : {}
		isChannel : true
		bufferMode : false

	# Get the nickname for the active network
	netNickname : (network) -> 
		curnet = this.get "currentNetwork"
		nets = this.get "networks."+curnet
		return if nets? then nets.nickname else null

	# Add message to list
	addMessage : (data) ->
		nets = this.get "networks"
		if data.channel is this.netNickname(data.network) or data.channel is data.nickname
			# Is a query and it's not created? Create it already!
			if not nets[data.network].chans[data.nickname]?
				nets[data.network].chans[data.nickname] = new Channel {key: data.nickname, id: data.nickname}
				nets[data.network].chans[data.nickname].isquery = true
				this.set "networks", nets
			data.channel = data.nickname
		if not this.get("messages."+data.network+"."+data.channel)?
			this.set "messages."+data.network+"."+data.channel, []
		# Get last message author (for omission)
		m = this.get "messages."+data.network+"."+data.channel
		if m[m.length - 1]?
			omitnick = true if m[m.length - 1].user is data.nickname
		# Check for mentions
		mentioned = data.message.indexOf(this.netNickname(data.network)) >= 0
		# Push message to the list
		m
		this.get("messages."+data.network+"."+data.channel).push { type:"message", shownick: !omitnick?, user: data.nickname, message: this.processMessage(data.message), timestamp: formatTime(data.time), mentioned: mentioned }

		return if this.get("bufferMode") or data.channel is data.nickname
		if data.network isnt this.currentNetwork() or data.channel isnt this.currentChannel()
			nets[data.network].chans[data.channel].unread nets[data.network].chans[data.channel].unread() + 1
			if mentioned
				nets[data.network].chans[data.channel].mentioned true
				if window.notifications then showNotification "Mentioned!", data.nickname + " mentioned you on " + data.channel + "!"
		else
			scrollBottom()

	# Add notice to list
	addNotice : (data) ->
		# Stick notices to active channel if same network
		net = data.network
		if not this.get("bufferMode") and data.network is this.get("currentNetwork") and data.nickname? and data.nickname isnt "" and servernicks.indexOf(data.nickname.toLowerCase()) < 0 and data.channel isnt "*"
			chan = this.get "currentChannel"
		else
			chan = ":status"
		if not this.get("messages."+net+"."+chan)?
			this.set "messages."+net+"."+chan, []
		this.get("messages."+net+"."+chan).push { type:"notice", channel: data.channel, user: data.nickname, message: this.processMessage(data.message), timestamp: formatTime data.time }
		if chan is ":status"
			this.get("networks."+net).unread += 1
		scrollBottom()

	# Add channel action to list
	addChannelAction : (type, data) ->
		switch type
			when "join"
				if !this.get("bufferMode") and data.nickname == this.netNickname data.network
					interop.socket.emit "chaninfo", {network:data.network,channel:data.channel}
					return
				if !this.get("messages."+data.network+"."+data.channel)?
					this.set "messages."+data.network+"."+data.channel, []
				# Write join message
				this.get("messages."+data.network+"."+data.channel).push { type:"chaction", message: "<b>" + data.nickname + "</b>  has joined the channel", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if this.get("bufferMode")
				# Add user to list
				this.get("userlist."+data.network+"."+data.channel).push new User data.nickname,""
			when "part","kick","quit"
				if !this.get("bufferMode") and data.nickname == this.netNickname data.network
					# Select another channel if we're on the parted one
					this.switchTo data.network, ":status", false
					# Get the channel to remove
					nets = this.networks()
					# Remove channel from list
					delete nets[data.network].chans[data.channel]
					this.networks nets
					return
				# Write part/kick message
				data.reason = ifval data.reason, ""
				switch type
					when "part"
						if !this.get("messages."+data.network+"."+data.channel)?
							this.set "messages."+data.network+"."+data.channel, []
						this.get("messages."+data.network+"."+data.channel).push { type:"chaction", message: "<b>" + data.nickname + "</b>  has left the channel (" + data.reason + ")", timestamp: formatTime data.time }
					when "kick"
						if !this.get("messages."+data.network+"."+data.channel)?
							this.set "messages."+data.network+"."+data.channel, []
						this.get("messages."+data.network+"."+data.channel).push { type:"chaction", message: "<b>" + data.nickname + "</b>  has been kicked by <b>" + data.by + "</b> (" + data.reason + ")", timestamp: formatTime data.time }
					when "quit"
						# Fix channel bug (just in case)
						if !Array.isArray data.channels
							data.channels = [data.channels]
						reason = ifval data.reason, ""
						for chan in data.channels
							if !this.messages[data.network+"."+chan]?
								this.messages[data.network+"."+chan] = []
							# Write quit message
							this.messages[data.network+"."+chan].push { type:"chaction", message: "<b>" + data.nickname + "</b> has quit (" + reason + ")", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if this.get("bufferMode")
				# Delete user from list
				ulist = this.userlist()
				# Part and Kick involve only one channel
				if type isnt "quit"
					channels = [data.channel]
				else
					channels = data.channels
				for chan in channels
					indexChan = data.network+"."+chan
					indexUser = filterSingle ulist[indexChan], (x) -> x.nick() == data.nickname
					ulist[indexChan].splice indexUser.id, 1 if indexUser.id >= 0
					this.userlist ulist
			when "mode"
				data.by = ifval data.by, data.network
				# Add/remove symbol from user if someone was affected (unless in buffermode)
				if data.argument? and modeSymbol[data.mode]? and not this.get("bufferMode")
					ulist = this.userlist()
					indexChan = data.network+"."+data.channel
					indexUser = filterSingle ulist[indexChan], (x) -> x.nick() == data.argument
					if indexUser.id >= 0
						modesym = modeSymbol[data.mode]
						ustring = ulist[indexChan][indexUser.id].val()
						# Add or remove?
						if data.what is "+"
							ustring += modesym
							ustring = ustring.split("").sort(this.modeSort).join ""
						else
							uindex = ustring.indexOf modesym if uindex >= 0
							uvals = ustring.split ""
							uvals.splice uindex, 1 
							ustring = uvals.join ""
						ulist[indexChan][indexUser.id].val ustring
						this.userlist ulist
				if not data.argument? then data.argument = ""
				if !this.get("messages."+data.network+"."+data.channel)?
					this.set "messages."+data.network+"."+data.channel, []
				# Write mode message
				this.get("messages."+data.network+"."+data.channel).push { type:"chaction", message: "<b>" + data.by + "</b>  sets mode " + data.what + data.mode + " " + data.argument, timestamp: formatTime data.time }
			when "nick"
				if !this.get("bufferMode") and data.oldnick == this.netNickname data.network
					nets = this.networks()
					nets[data.network].nickname = data.newnick
					this.networks nets
				# Fix channel bug (just in case)
				if !Array.isArray data.channels
					data.channels = [data.channels]
				for chan in data.channels
					if !this.get("messages."+data.network+"."+chan)?
						this.set "messages."+data.network+"."+chan, []
					# Write nick message
					this.get("messages."+data.network+"."+chan).push { type:"chaction", message: "<b>" + data.oldnick + "</b> is now <b>" + data.newnick + "</b>", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if this.get("bufferMode")
				# Modify user nick from list
				ulist = this.userlist()
				for chan in data.channels
					indexChan = data.network+"."+chan
					indexUser = filterSingle ulist[indexChan], (x) -> x.nick() == data.oldnick
					ulist[indexChan][indexUser.id].nick data.newnick if indexUser.id >= 0
				this.userlist ulist
			when "quit"
				this.switchTo data.network, ":status", false
				this.messages[data.network+".:status"].push { type:"chaction", message: "Disconnected from <b>" + data.network + "</b>", timestamp: formatTime data.time }
		scrollBottom()

	processMessage : (message) ->
		message = htmlEntities message # Strip harmful html
		message = linkify message # Linkify links
		# TODO: bold and other irc properties
		return message

	# Update channel info
	updateChannelInfo : (data) ->
		# Update userlist
		this.updateChannelUsers { network: data.network, channel: data.channeldata.key, nicks: data.channeldata.users }
		# Create or replace channel data
		this.set "networks."+data.network+".chans."+data.channeldata.key, new Channel data.channeldata
		# Update network/channel list
		this.set "isChannel", true
		this.set "currentNetwork", data.network
		this.set "currentChannel", data.channeldata.key

	# Update channel users (userlists)
	updateChannelUsers : (data) ->
		ulist = (new User uname,uval for uname,uval of data.nicks)
		this.set "userlist."+data.network+"."+data.channel, ulist

	# Get the networks and channels joined and format them so they can be loaded into Ractive
	initNetworks : (data) ->
		for nid,network of data
			for cname, cval of network.chans
				this.updateChannelUsers { network: nid, channel: cname, nicks: cval.users }
			# Create channels from objects
			chanobjs = {}
			chanobjs[cid] = new Channel chan for cid,chan of data[nid].chans
			data[nid].chans = chanobjs
			data[nid].unread = 0
		this.set "networks", data
		this.set "currentNetwork", Object.keys(data)[0]
		this.set "currentChannel", Object.keys(data[Object.keys(data)[0]].chans)[0].key
		return

window.servernicks = ["infoserv", "global"]
# Mode order
window.modeOrder = "+%@&~"
window.modeSymbol = {"v":"+", "h":"%", "o":"@", "a":"&", "q":"~"}
window.notifications = false
wordComplete = null
lastIndex = 0
currentMessage = ""
$(document).ready () ->
	window.interface = new Interface
		el: 'container'
		template : '#template'
	window.interface.on 'sendMessage', (event) ->
		event.original.preventDefault()

	window.interface.observe 'messageBar', (val) ->
		currentMessage = val

	$("#linkNotify").on "click", (e) ->
		# Request permission for desktop notifications if needed
		if window.webkitNotifications
			notifies = checkNotifications()
			if notifies is 1 then window.webkitNotifications.requestPermission checkNotifications
			if notifies is 0 then window.notifications = true

	# Check if authentication is needed
	$.get "/useAuth", (data) ->
		if data == "true"
			window.interface.AuthDialog()
		else 
			interop.createSocket()
	$("#autherr").on 'uk.modal.hide', () -> location.reload()

	# Autocompletion
	$("#inputbarcont").on "keydown", '#inputbar', (event) ->
		keyCode = event.keyCode || event.which
		if keyCode == 9
			event.preventDefault()
			words = $("#inputbar").val().split " "
			if window.interface.get('isChannel')
				net = window.interface.get "currentNetwork"
				chan = window.interface.get "currentChannel"
				wordComplete = words[words.length-1] if wordComplete == null
				users = window.interface.get("userlist."+net+"."+chan).filter (elem) ->
					elem.nick.toLowerCase().indexOf(wordComplete.toLowerCase()) == 0
				lastIndex = 0 if lastIndex >= users.length
				words[words.length-1] = users[lastIndex].nick
				lastIndex++
			else
				words[words.length-1] = window.interface.get "currentChannel"
			currentMessage = words.join " "
		else
			wordComplete = null if wordComplete != null


checkNotifications = () ->
	switch window.webkitNotifications.checkPermission()
		when 0
			# We haz notifications, hooway!.
			window.notifications = true
			return 0
		when 1
			# We need to ask :O
			return 1
		when 2
			# He doesn't want them :(
			window.notifications = false
			return 2

showNotification = (title,message) ->
	icon = "/images/icon32.png"
	notification = window.webkitNotifications.createNotification icon, title, message
	notification.show()