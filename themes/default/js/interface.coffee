InterfaceViewModel = () ->
	self = this

	# Network and channel list
	self.networks = ko.observableArray []
	self.currentNetwork = ko.observable ""
	self.currentChannel = ko.observable ""
	self.messageBar = ko.observable ""
	self.userlist = ko.observable {}
	self.messages = ko.observable {}
	self.isChannel = true
	self.bufferMode = false

	# Get the user list for the active channel
	self.channelUsers = ko.computed () -> self.userlist()[self.currentNetwork()+self.currentChannel()]

	# Get the activity for the active channel
	self.channelActivity = ko.computed () -> self.messages()[self.currentNetwork()+self.currentChannel()]

	# Get the user list for the active channel
	self.currentTopic = ko.computed () ->
		nets = self.networks()
		curnet = self.currentNetwork()
		curchan = self.currentChannel()
		return false unless self.isChannel and nets isnt [] and curnet isnt "" and curchan isnt ""
		net = filterSingle nets, (x) -> x.id == curnet
		chan = filterSingle nets[net.id].chans, (x) -> x.key == curchan
		topic = nets[net.id].chans[chan.id].topic
		tnick = nets[net.id].chans[chan.id].topicBy
		return if topic? then {topic:topic, topicBy:tnick} else false

	# Get the nickname for the active network
	self.currentNickname = ko.computed () -> 
		curnet = self.currentNetwork()
		nets = filterSingle self.networks(), (x) -> x.id == curnet
		return if nets? then nets.elem.nickname else null

	# Get the nickname for the active network
	self.netNickname = (network) -> 
		curnet = self.currentNetwork()
		nets = filterSingle self.networks(), (x) -> x.id == network
		return if nets? then nets.elem.nickname else null

	# Add message to list
	self.addMessage = (data) ->
		msgs = self.messages()
		if !msgs[data.network+data.channel]?
			msgs[data.network+data.channel] = []
		# Get last message author (for omission)
		m = msgs[data.network+data.channel]
		if m[m.length - 1]?
			omitnick = true if m[m.length - 1].user is data.nickname
		# Push message to the list
		msgs[data.network+data.channel].push { type:"message", shownick: !omitnick?, user: data.nickname, message: data.message, timestamp: formatTime data.time }
		self.messages msgs
		# Scroll message list
		scrollBottom()

	# Add notice to list
	self.addNotice = (data) ->
		# Stick notices to active channel
		curchan = self.currentChannel()
		curnet = self.currentNetwork()
		msgs = self.messages()
		if !msgs[curnet+curchan]?
			msgs[curnet+curchan] = []
		msgs[curnet+curchan].push { type:"notice", channel: data.channel, user: data.nickname, message: data.message, timestamp: formatTime data.time }
		self.messages msgs
		scrollBottom()

	# Add channel action to list
	self.addChannelAction = (type, data) ->
		msgs = self.messages()
		if !msgs[data.network+data.channel]?
			msgs[data.network+data.channel] = []
		switch type
			when "join"
				if data.nickname == self.netNickname data.network
					interop.socket.emit "chaninfo", {network:data.network,channel:data.channel}
					return
				# Write join message
				msgs[data.network+data.channel].push { type:"chaction", message: data.nickname + " has joined the channel.", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if self.bufferMode
				# Add user to list
				ulist = self.userlist()
				ulist[data.network+data.channel].push data.nickname
				self.userlist ulist
			when "part"
				if data.nickname == self.netNickname data.network
					# Select another channel if we're on the parted one
					self.switchTo data.network, ":status", false
					# Get the channel to remove
					nets = self.networks()
					net = filterSingle nets, (x) -> x.id == data.network
					chan = filterSingle nets[net.id].chans, (x) -> x.key == data.channel
					# Remove channel from list
					nets[net.id].chans.splice chan, 1
					self.networks nets
					return
				# Write part message
				msgs[data.network+data.channel].push { type:"chaction", message: data.nickname + " has left the channel.", timestamp: formatTime data.time }
				# If we're in buffer mode we don't need to alter the list
				break if self.bufferMode
				# Delete user from list
				ulist = self.userlist()
				indexChan = data.network+data.channel
				indexUser = ulist[indexChan].indexOf data.nickname
				ulist[indexChan].splice (ulist[indexChan].indexOf data.nickname), 1 if indexUser > 0
				self.userlist ulist
		self.messages msgs
		scrollBottom()

	# Add message to list
	self.addError = (message) ->
		curchan = self.currentChannel()
		curnet = self.currentNetwork()
		msgs = self.messages()
		if !msgs[curnet+curchan]?
			msgs[curnet+curchan] = []
		msgs[curnet+curchan].push { type:"error", user:"", message: message }
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
		self.isChannel = isChannel
		self.currentNetwork network
		self.currentChannel channel

	# Update channel info
	self.updateChannelInfo = (data) ->
		nets = self.networks()
		# Find network and channel
		net  = filterSingle self.networks(), (x) -> x.id == data.network
		chan = filterSingle nets[net.id].chans, (x) -> x.key == data.channeldata.key
		# Update userlist
		self.updateChannelUsers { network: data.network, channel: data.channeldata.key, nicks: data.channeldata.users }
		# Create or replace channel data
		if chan?
			nets[net.id].chans[chan.id] = data.channeldata
		else
			nets[net.id].chans.push data.channeldata
		# Update network/channel list
		self.networks nets

	# Update channel users (userlists)
	self.updateChannelUsers = (data) ->
		indexChan = data.network+data.channel
		ulist = self.userlist()
		uchan = []
		for uname,uval of data.nicks
			uchan.push uname
		ulist[indexChan] = uchan
		self.userlist ulist

	# Set new topic
	self.setTopic = (data) ->
		nets = self.networks()
		net = filterSingle nets, (x) -> x.id == data.network
		chan = filterSingle nets[net.id].chans, (x) -> x.key == data.channel
		nets[net.id].chans[chan.id].topic = data.topic
		nets[net.id].chans[chan.id].topicBy = data.nickname
		self.networks nets
		# Create message with topic change
		msgs = self.messages()
		if !msgs[data.network+data.channel]?
			msgs[data.network+data.channel] = []
		msgs[data.network+data.channel].push { type:"chaction", message: data.nickname + " has set the topic to: " + data.topic, timestamp: formatTime data.time }
		self.messages msgs
		scrollBottom()

	# Get the networks and channels joined and format them so they can be loaded into Knockout
	self.initNetworks = (data) ->
		tdata = []
		udata = {}
		# Put networks on array structure
		for nid,network of data
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
		self.networks tdata
		self.userlist udata
		self.currentNetwork tdata[0].id if tdata[0]?
		self.currentChannel tdata[0].chans[0].key if tdata[0].chans[0]?
		return
	return

window.interface = new InterfaceViewModel()

$(document).ready () ->
	ko.applyBindings window.interface