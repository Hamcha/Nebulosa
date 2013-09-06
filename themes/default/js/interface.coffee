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

	# Add message to list
	self.addMessage = (data) ->
		msgs = self.messages()
		if !msgs[data.network+data.channel]?
			msgs[data.network+data.channel] = []
		msgs[data.network+data.channel].push { type:"message", user: data.nickname, message: data.message }
		self.messages msgs
		scrollBottom()

	# Add notice to list
	self.addNotice = (data) ->
		# Stick notices to active channel
		curchan = self.currentChannel()
		curnet = self.currentNetwork()
		msgs = self.messages()
		if !msgs[curnet+curchan]?
			msgs[curnet+curchan] = []
		msgs[curnet+curchan].push { type:"notice", channel: data.channel, user: data.nickname, message: data.message }
		self.messages msgs
		scrollBottom()

	# Add channel action to list
	self.addChannelAction = (type, data) ->
		msgs = self.messages()
		if !msgs[data.network+data.channel]?
			msgs[data.network+data.channel] = []
		switch type
			when "join"
				return if data.nickname is self.currentNickname()
				# Add user to list
				ulist = self.userlist()
				ulist[data.network+data.channel].push data.nickname
				self.userlist ulist
				# Write join message
				msgs[data.network+data.channel].push { type:"chaction", message: data.nickname + " has joined the channel." }
			when "part"
				return if data.nickname is self.currentNickname()
				# Delete user from list
				ulist = self.userlist()
				indexChan = data.network+data.channel
				indexUser = ulist[indexChan].indexOf data.nickname
				ulist[indexChan].splice (ulist[indexChan].indexOf data.nickname), 1 if indexUser > 0
				self.userlist ulist
				# Write part message
				msgs[data.network+data.channel].push { type:"chaction", message: data.nickname + " has left the channel." }
		self.messages msgs
		scrollBottom()

	# Send message to server
	self.sendMessage = () ->
		# Get vars to avoid calling them multiple times
		tonet = self.currentNetwork()
		tochn = self.currentChannel()
		curnick = self.currentNickname()
		message = self.messageBar()
		# Send message to Nebulosa
		interop.socket.emit "message", { network: tonet, channel: tochn, message: message, nickname: curnick }
		# Add the message to the list (client-side stuff)
		self.addMessage { network: tonet, nickname: self.currentNickname(), channel: tochn, message: message }
		# Empty the message bar
		self.messageBar ""

	# Switch to another channel
	self.switchTo = (network,channel,isChannel) ->
		self.isChannel = isChannel
		self.currentNetwork network
		self.currentChannel channel

	# Update channel info (userlists)
	self.updateChannelInfo = (data) ->
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
		msgs[data.network+data.channel].push { type:"chaction", message: data.nickname + " has set the topic to: " + data.topic }
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