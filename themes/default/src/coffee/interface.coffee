Channel = (cdata) ->
	this.created = cdata.created
	this.key = cdata.key
	this.isquery = false
	this.unread = ko.observable 0
	this.mentioned = ko.observable false
	this.serverName = cdata.serverName
	this.mode = ko.observable cdata.mode
	this.topic = cdata.topic if cdata.topic?
	this.topicBy = cdata.topicBy if cdata.topicBy?
	return

User = (nick,val) ->
	this.nick = ko.observable nick
	this.val = ko.observable val
	return

InterfaceViewModel = () ->
	self = this

	# Network and channel list
	self.networks = ko.observable {}
	self.currentNetwork = ko.observable ""
	self.currentChannel = ko.observable ""
	self.messageBar = ko.observable ""
	self.userlist = ko.observable {}
	self.messages = ko.observable {}
	self.isChannel = true
	self.bufferMode = false

	self.networkList = ko.computed () ->
		tdata = []
		udata = {}
		# Put networks on array structure
		for nid,network of self.networks()
			tnet = {}
			tnet.nickname = network.nickname
			tnet.name = network.name
			tnet.id = nid
			tnet.chans = []
			# Put chans on array structure
			for cname, cval of network.chans
				cval.id = cname
				cval.unread() # Fix because Knockout.js is retarded
				tnet.chans.push cval
				# Prepare userlist
				uchan = []
				for uname,uval of cval.users
					uchan.push uname
				udata[tnet.id+cname] = uchan
			tdata.push tnet
		return tdata

	# Get the user list for the active channel
	self.channelUsers = ko.computed () -> 
		ulist = self.userlist()[self.currentNetwork()+"."+self.currentChannel()]
		return unless ulist?
		ulist.sort self.nickSort
		return ulist

	# Get the activity for the active channel
	self.channelActivity = ko.computed () -> self.messages()[self.currentNetwork()+"."+self.currentChannel()].slice -50 if self.messages()[self.currentNetwork()+"."+self.currentChannel()]?

	# Get the user list for the active channel
	self.currentTopic = ko.computed () ->
		nets = self.networks()
		curnet = self.currentNetwork()
		curchan = self.currentChannel()
		return false unless self.isChannel and nets isnt [] and curnet isnt "" and curchan isnt "" and nets[curnet].chans[curchan]?
		topic = nets[curnet].chans[curchan].topic
		tnick = nets[curnet].chans[curchan].topicBy
		return if topic? then {topic:topic, topicBy:tnick} else false

	# Get the nickname for the active network
	self.currentNickname = ko.computed () -> 
		curnet = self.currentNetwork()
		nets = self.networks()[curnet]
		return if nets? then nets.nickname else null

	# Get the nickname for the active network
	self.netNickname = (network) -> 
		curnet = self.currentNetwork()
		nets = self.networks()[curnet]
		return if nets? then nets.nickname else null

	# Add message to list
	self.addMessage = (data) ->
		msgs = self.messages()
		nets = self.networks()
		if data.channel is self.netNickname(data.network) or data.channel is data.nickname
			# Is a query and it's not created? Create it already!
			if not nets[data.network].chans[data.nickname]?
				nets[data.network].chans[data.nickname] = new Channel {key: data.nickname, id: data.nickname}
				nets[data.network].chans[data.nickname].isquery = true
				self.networks nets
			data.channel = data.nickname
		if not msgs[data.network+"."+data.channel]?
			msgs[data.network+"."+data.channel] = []
		# Get last message author (for omission)
		m = msgs[data.network+"."+data.channel]
		if m[m.length - 1]?
			omitnick = true if m[m.length - 1].user is data.nickname
		# Check for mentions
		mentioned = data.message.indexOf(self.netNickname(data.network)) >= 0
		# Push message to the list
		msgs[data.network+"."+data.channel].push { type:"message", shownick: !omitnick?, user: data.nickname, message: self.processMessage(data.message), timestamp: formatTime(data.time), mentioned: mentioned }
		self.networks nets
		self.messages msgs

		return if self.bufferMode and data.channel is data.nickname
		if data.network isnt self.currentNetwork() or data.channel isnt self.currentChannel()
			nets[data.network].chans[data.channel].unread nets[data.network].chans[data.channel].unread() + 1
			if mentioned
				nets[data.network].chans[data.channel].mentioned true
				if window.notifications then showNotification "Mentioned!", data.nickname + " mentioned you on " + data.channel + "!"
		else
			scrollBottom()

	# Add notice to list
	self.addNotice = (data) ->
		# Stick notices to active channel if same network
		net = data.network
		if not self.bufferMode and data.network is self.currentNetwork() and data.nickname? and data.nickname isnt "" and servernicks.indexOf(data.nickname.toLowerCase()) < 0 and data.channel isnt "*"
			chan = self.currentChannel()
		else
			chan = ":status"
		msgs = self.messages()
		if !msgs[net+"."+chan]?
			msgs[net+"."+chan] = []
		msgs[net+"."+chan].push { type:"notice", channel: data.channel, user: data.nickname, message: self.processMessage(data.message), timestamp: formatTime data.time }
		self.messages msgs
		if chan is ":status"
			nets = self.networks()
			nets[data.network].unread += 1
		scrollBottom()

	# Add channel action to list
	self.addChannelAction = (type, data) ->
		msgs = self.messages()
		switch type
			when "join"
				if !self.bufferMode and data.nickname == self.netNickname data.network
					interop.socket.emit "chaninfo", {network:data.network,channel:data.channel}
					return
				if !msgs[data.network+"."+data.channel]?
					msgs[data.network+"."+data.channel] = []
				# Write join message
				msgs[data.network+"."+data.channel].push { type:"chaction", message: "<b>" + data.nickname + "</b>  has joined the channel", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if self.bufferMode
				# Add user to list
				ulist = self.userlist()
				ulist[data.network+"."+data.channel].push new User data.nickname,""
				self.userlist ulist
			when "part","kick","quit"
				if !self.bufferMode and data.nickname == self.netNickname data.network
					# Select another channel if we're on the parted one
					self.switchTo data.network, ":status", false
					# Get the channel to remove
					nets = self.networks()
					# Remove channel from list
					delete nets[data.network].chans[data.channel]
					self.networks nets
					return
				# Write part/kick message
				data.reason = ifval data.reason, ""
				switch type
					when "part"
						if !msgs[data.network+"."+data.channel]?
							msgs[data.network+"."+data.channel] = []
						msgs[data.network+"."+data.channel].push { type:"chaction", message: "<b>" + data.nickname + "</b>  has left the channel (" + data.reason + ")", timestamp: formatTime data.time }
					when "kick"
						if !msgs[data.network+"."+data.channel]?
							msgs[data.network+"."+data.channel] = []
						msgs[data.network+"."+data.channel].push { type:"chaction", message: "<b>" + data.nickname + "</b>  has been kicked by <b>" + data.by + "</b> (" + data.reason + ")", timestamp: formatTime data.time }
					when "quit"
						# Fix channel bug (just in case)
						if !Array.isArray data.channels
							data.channels = [data.channels]
						reason = ifval data.reason, ""
						for chan in data.channels
							if !msgs[data.network+"."+chan]?
								msgs[data.network+"."+chan] = []
							# Write quit message
							msgs[data.network+"."+chan].push { type:"chaction", message: "<b>" + data.nickname + "</b> has quit (" + reason + ")", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if self.bufferMode
				# Delete user from list
				ulist = self.userlist()
				# Part and Kick involve only one channel
				if type isnt "quit"
					channels = [data.channel]
				else
					channels = data.channels
				for chan in channels
					indexChan = data.network+"."+chan
					indexUser = filterSingle ulist[indexChan], (x) -> x.nick() == data.nickname
					ulist[indexChan].splice indexUser.id, 1 if indexUser.id >= 0
					self.userlist ulist
			when "mode"
				data.by = ifval data.by, data.network
				# Add/remove symbol from user if someone was affected (unless in buffermode)
				if data.argument? and modeSymbol[data.mode]? and not self.bufferMode
					ulist = self.userlist()
					indexChan = data.network+"."+data.channel
					indexUser = filterSingle ulist[indexChan], (x) -> x.nick() == data.argument
					if indexUser.id >= 0
						modesym = modeSymbol[data.mode]
						ustring = ulist[indexChan][indexUser.id].val()
						# Add or remove?
						if data.what is "+"
							ustring += modesym
							ustring = ustring.split("").sort(self.modeSort).join ""
						else
							uindex = ustring.indexOf modesym if uindex >= 0
							uvals = ustring.split ""
							uvals.splice uindex, 1 
							ustring = uvals.join ""
						ulist[indexChan][indexUser.id].val ustring
						self.userlist ulist
				if not data.argument? then data.argument = ""
				if !msgs[data.network+"."+data.channel]?
					msgs[data.network+"."+data.channel] = []
				# Write mode message
				msgs[data.network+"."+data.channel].push { type:"chaction", message: "<b>" + data.by + "</b>  sets mode " + data.what + data.mode + " " + data.argument, timestamp: formatTime data.time }
			when "nick"
				if !self.bufferMode and data.oldnick == self.netNickname data.network
					nets = self.networks()
					nets[data.network].nickname = data.newnick
					self.networks nets
				# Fix channel bug (just in case)
				if !Array.isArray data.channels
					data.channels = [data.channels]
				for chan in data.channels
					if !msgs[data.network+"."+chan]?
						msgs[data.network+"."+chan] = []
					# Write nick message
					msgs[data.network+"."+chan].push { type:"chaction", message: "<b>" + data.oldnick + "</b> is now <b>" + data.newnick + "</b>", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if self.bufferMode
				# Modify user nick from list
				ulist = self.userlist()
				for chan in data.channels
					indexChan = data.network+"."+chan
					indexUser = filterSingle ulist[indexChan], (x) -> x.nick() == data.oldnick
					ulist[indexChan][indexUser.id].nick data.newnick if indexUser.id >= 0
				self.userlist ulist
			when "quit"
				self.switchTo data.network, ":status", false
				msgs[data.network+".:status"].push { type:"chaction", message: "Disconnected from <b>" + data.network + "</b>", timestamp: formatTime data.time }
		self.messages msgs
		scrollBottom()

	# Add message to list
	self.addError = (message) ->
		curchan = self.currentChannel()
		curnet = self.currentNetwork()
		msgs = self.messages()
		if !msgs[curnet+"."+curchan]?
			msgs[curnet+"."+curchan] = []
		msgs[curnet+"."+curchan].push { type:"error", user:"", message: message }
		self.messages msgs
		scrollBottom()

	# Add message to list
	self.addWhois = (data) ->
		curchan = self.currentChannel()
		curnet = self.currentNetwork()
		msgs = self.messages()
		if !msgs[curnet+"."+curchan]?
			msgs[curnet+"."+curchan] = []
		# Beautify whois data
		ninfo = [
			"<b>" + data.info.nick + "</b> is " + data.info.realname + " (" + data.info.user + "@" + data.info.host + ")",
			"&nbsp;&nbsp;&nbsp;&nbsp;is on <b>" + (data.info.channels.join ", ") + "</b>",
			"&nbsp;&nbsp;&nbsp;&nbsp;is on " + data.info.server + " (" + data.info.serverinfo + ")"
		]
		ninfo.push "&nbsp;&nbsp;&nbsp;&nbsp;has been idle " + toTimeStr data.info.idle if data.info.idle?
		msgs[curnet+"."+curchan].push { type:"whois", user:"", nickname:data.info.nick, info:ninfo }
		self.messages msgs
		scrollBottom()

	self.processMessage = (message) ->
		# Strip harmful html
		message = htmlEntities message
		# Linkify links
		message = linkify message
		# TODO: bold and other irc properties
		return message

	# Send message to server
	self.sendMessage = () ->
		# Get vars to avoid calling them multiple times
		tonet = self.currentNetwork()
		tochn = self.currentChannel()
		curnick = self.currentNickname()
		message = self.messageBar()
		# Check if it's a command (/something, not //something)
		if message[0] == "/" && message[1]? && message[1] != "/"
			# Get all the parameters (removing the trailing slash)
			parts = message.substring(1).split " "
			action = parts.splice 0,1
			if !interop.command[action]?
				self.addError "Unsupported command (" + action + ")"
			else
				interop.command[action] tonet, tochn, curnick, parts
		else
			# Replace initial // with /
			message = message.replace(/^\/\//,"/")
			return if message == "" # Can't send empty messages
			# Not a command, so send the message to Nebulosa
			interop.socket.emit "message", { network: tonet, channel: tochn, message: message, nickname: curnick }
			# Add the message to the list (client-side stuff)
			self.addMessage { network: tonet, nickname: self.currentNickname(), channel: tochn, message: message, time: +new Date }
		# Empty the message bar
		self.messageBar ""

	# Switch to another channel
	self.switchTo = (network,channel,isChannel) ->
		# Are we switching layout?
		if self.isChannel != isChannel
			if isChannel
				$("#rightbar").removeClass("hiddenbar");
				$("#centerbar").removeClass("superwide");
				$("#centerbar").addClass("normalwide");
			else
				$("#rightbar").addClass("hiddenbar");
				$("#centerbar").removeClass("normalwide");
				$("#centerbar").addClass("superwide");
			self.isChannel = isChannel
		self.currentNetwork network
		self.currentChannel channel
		scrollBottom()
		if channel != ":status"
			# Remove unread state
			nets = self.networks()
			nets[network].chans[channel].unread 0
			nets[network].chans[channel].mentioned false
			self.networks nets

	# Update channel info
	self.updateChannelInfo = (data) ->
		nets = self.networks()
		# Update userlist
		self.updateChannelUsers { network: data.network, channel: data.channeldata.key, nicks: data.channeldata.users }
		# Create or replace channel data
		nets[data.network].chans[data.channeldata.key] = new Channel data.channeldata
		# Update network/channel list
		self.networks nets
		self.isChannel = true
		self.currentNetwork data.network
		self.currentChannel data.channeldata.key

	# Update channel users (userlists)
	self.updateChannelUsers = (data) ->
		indexChan = data.network+"."+data.channel
		ulist = self.userlist()
		uchan = []
		# Push nicks into array
		uchan.push new User uname,uval for uname,uval of data.nicks
		ulist[indexChan] = uchan
		self.userlist ulist

	# Set new topic
	self.setTopic = (data) ->
		nets = self.networks()
		return unless nets[data.network].chans[data.channel]?
		nets[data.network].chans[data.channel].topic = data.topic
		nets[data.network].chans[data.channel].topicBy = data.nickname
		self.networks nets
		# Create message with topic change
		msgs = self.messages()
		if !msgs[data.network+"."+data.channel]?
			msgs[data.network+"."+data.channel] = []
		msgs[data.network+"."+data.channel].push { type:"chaction", message: data.nickname + " has set the topic to: " + data.topic, timestamp: formatTime data.time }
		self.messages msgs
		scrollBottom()

	# Get the networks and channels joined and format them so they can be loaded into Knockout
	self.initNetworks = (data) ->
		for nid,network of data
			for cname, cval of network.chans
				self.updateChannelUsers { network: nid, channel: cname, nicks: cval.users }
			# Create channels from objects
			chanobjs = {}
			chanobjs[cid] = new Channel chan for cid,chan of data[nid].chans
			data[nid].chans = chanobjs
			data[nid].unread = 0
		self.networks data
		nets = self.networkList()
		self.currentNetwork nets[0].id if nets[0]?
		self.currentChannel nets[0].chans[0].key if nets[0].chans[0]?
		return

	self.nickSort = (a,b) ->
		# Return the one with a mode set
		return  1 if a.val() == "" and b.val() != ""
		return -1 if b.val() == "" and a.val() != ""
		# Return the one with higher mode
		if b.val() != a.val()
			return  1 if modeOrder.indexOf(b.val()[0]) > modeOrder.indexOf(a.val()[0]) 
			return -1 if modeOrder.indexOf(b.val()[0]) < modeOrder.indexOf(a.val()[0]) 
		# Otherwise sort on alphabetical sorting
		return  1 if b.nick() < a.nick()
		return -1 if b.nick() > a.nick()
		return  0

	self.modeSort = (a,b) -> modeOrder.indexOf(a) - modeOrder.indexOf(b)

	self.AuthError = () ->
		modal = new $.UIkit.modal.Modal "#autherr"
		modal.show()

	self.Exception = (data, fatal) ->
		fatal = false unless fatal?
		$("#generrcnt").html "<h2>Oops..</h2><p>"+data+"</p>"
		modal = new $.UIkit.modal.Modal "#generr"
		modal.options.bgclose = modal.options.keyboard = false if fatal
		modal.show()

	self.AuthDialog = () ->
		self.authdialog = new $.UIkit.modal.Modal "#authdlg" unless self.authdialog?
		self.authdialog.options.bgclose = self.authdialog.options.keyboard = false
		self.authdialog.show()
		user = document.cookie.replace(/(?:(?:^|.*;\s*)user\s*\=\s*([^;]*).*$)|^.*$/, "$1");
		pass = document.cookie.replace(/(?:(?:^|.*;\s*)pass\s*\=\s*([^;]*).*$)|^.*$/, "$1");
		$("#autocred").hide() unless user isnt "" or pass isnt ""
		$("#userauth").val user if user isnt ""
		$("#pwdauth").val pass if pass isnt ""
		$("#userauth").focus()

	self.auth = (formdata) ->
		formdata.username.className = if formdata.username.value is "" then "uk-form-danger" else ""
		formdata.password.className = if formdata.password.value is "" then "uk-form-danger" else ""
		return if formdata.password.value is "" or formdata.username.value is ""
		self.authdialog.hide()
		interop.createSocket formdata.username.value,formdata.password.value

	return

window.servernicks = ["infoserv", "global"]
window.interface = new InterfaceViewModel()
# Mode order
window.modeOrder = "+%@&~"
window.modeSymbol = {"v":"+", "h":"%", "o":"@", "a":"&", "q":"~"}
window.notifications = false
wordComplete = null
lastIndex = 0
$(document).ready () ->
	# Apply Knockout bindings
	ko.applyBindings window.interface

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
	$("#inputbarcont").on "keydown", '#inputbar', (e) ->
		keyCode = e.keyCode || e.which; 
		if keyCode == 9
			words = $("#inputbar").val().split " "
			if window.interface.isChannel
				wordComplete = words[words.length-1] if wordComplete == null
				users = window.interface.channelUsers().filter (elem) ->
					elem.nick().toLowerCase().indexOf(wordComplete.toLowerCase()) == 0
				lastIndex = 0 if lastIndex >= users.length
				words[words.length-1] = users[lastIndex].nick()
				lastIndex++
			else
				words[words.length-1] = window.interface.currentChannel()
			window.interface.messageBar words.join " "
			e.preventDefault()
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