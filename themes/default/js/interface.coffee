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
				tnet.chans.push cval
				# Prepare userlist
				uchan = []
				for uname,uval of cval.users
					uchan.push uname
				udata[tnet.id+cname] = uchan
			tdata.push tnet
		return tdata

	# Get the user list for the active channel
	self.channelUsers = ko.computed () -> self.userlist()[self.currentNetwork()+"."+self.currentChannel()]

	# Get the activity for the active channel
	self.channelActivity = ko.computed () -> self.messages()[self.currentNetwork()+"."+self.currentChannel()]

	# Get the user list for the active channel
	self.currentTopic = ko.computed () ->
		nets = self.networks()
		curnet = self.currentNetwork()
		curchan = self.currentChannel()
		return false unless self.isChannel and nets isnt [] and curnet isnt "" and curchan isnt "" and curchan in nets[curnet].chans
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
		# Is a query and it's not created? Create it already!
		if data.channel is self.netNickname(data.network)
			if !nets[data.network].chans[data.nickname]?
				nets[data.network].chans[data.nickname] = {key: data.nickname, id: data.nickname}
				nets[data.network].chans[data.nickname] .isquery = true
				self.networks nets
			data.channel = data.nickname
		if !msgs[data.network+"."+data.channel]?
			msgs[data.network+"."+data.channel] = []
		# Get last message author (for omission)
		m = msgs[data.network+"."+data.channel]
		if m[m.length - 1]?
			omitnick = true if m[m.length - 1].user is data.nickname
		# Push message to the list
		msgs[data.network+"."+data.channel].push { type:"message", shownick: !omitnick?, user: data.nickname, message: data.message, timestamp: formatTime data.time }
		self.messages msgs
		# Scroll message list
		scrollBottom()

	# Add notice to list
	self.addNotice = (data) ->
		# Stick notices to active channel
		curchan = self.currentChannel()
		curnet = self.currentNetwork()
		msgs = self.messages()
		if !msgs[curnet+"."+curchan]?
			msgs[curnet+"."+curchan] = []
		msgs[curnet+"."+curchan].push { type:"notice", channel: data.channel, user: data.nickname, message: data.message, timestamp: formatTime data.time }
		self.messages msgs
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
				ulist[data.network+"."+data.channel].push data.nickname
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
					indexUser = ulist[indexChan].indexOf data.nickname
					ulist[indexChan].splice (ulist[indexChan].indexOf data.nickname), 1 if indexUser > 0
					self.userlist ulist
			when "mode"
				data.argument = ifval data.argument, ""
				data.by = ifval data.by, data.network
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
					indexUser = ulist[indexChan].indexOf data.oldnick
					ulist[indexChan][indexUser] = data.newnick if indexUser >= 0
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

	# Update channel info
	self.updateChannelInfo = (data) ->
		nets = self.networks()
		# Update userlist
		self.updateChannelUsers { network: data.network, channel: data.channeldata.key, nicks: data.channeldata.users }
		# Create or replace channel data
		nets[data.network].chans[data.channeldata.key] = data.channeldata
		nets[data.network].chans[data.channeldata.key].isquery = false
		# Update network/channel list
		self.networks nets
		self.currentNetwork data.network
		self.currentChannel data.channeldata.key

	# Update channel users (userlists)
	self.updateChannelUsers = (data) ->
		indexChan = data.network+"."+data.channel
		ulist = self.userlist()
		uchan = []
		for uname,uval of data.nicks
			uchan.push uname
		ulist[indexChan] = uchan
		self.userlist ulist

	# Set new topic
	self.setTopic = (data) ->
		nets = self.networks()
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
				data[nid].chans[cname].isquery = false
				self.updateChannelUsers { network: nid, channel: cname, nicks: cval.users }
		self.networks data
		nets = self.networkList()
		self.currentNetwork nets[0].id if nets[0]?
		self.currentChannel nets[0].chans[0].key if nets[0].chans[0]?
		return
	return

window.interface = new InterfaceViewModel()

$(document).ready () ->
	ko.applyBindings window.interface