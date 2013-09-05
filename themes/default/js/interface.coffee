InterfaceViewModel = () ->
	self = this

	# Network and channel list
	self.networks = ko.observableArray []
	self.currentNetwork = ko.observable "ponychat"
	self.currentChannel = ko.observable "#testbass"
	self.messageBar = ko.observable ""
	self.userlist = ko.observable {}
	self.messages = ko.observable {}

	# Get the user list for the active channel
	self.channelUsers = ko.computed () -> self.userlist()[self.currentNetwork()+self.currentChannel()]

	# Get the activity for the active channel
	self.channelActivity = ko.computed () -> self.messages()[self.currentNetwork()+self.currentChannel()]

	# Get the nickname for the active network
	self.currentNickname = ko.computed () -> 
		curnet = self.currentNetwork()
		nets = self.networks().filter (x) -> x.id == curnet
		return if nets[0]? then nets[0].nickname else null

	# Add message to list
	self.addMessage = (data) ->
		msgs = self.messages()
		if !msgs[data.network+data.to]?
			msgs[data.network+data.to] = []
		msgs[data.network+data.to].push { user: data.nickname, message: data.message }
		self.messages msgs

	# Send message to server
	self.sendMessage = () ->
		# Get vars to avoid calling them multiple times
		tonet = self.currentNetwork()
		tochn = self.currentChannel()
		message = self.messageBar()
		# Send message to Nebulosa
		interop.socket.emit "message", { network: tonet, channel: tochn, message: message }
		# Add the message to the list (client-side stuff)
		self.addMessage { network: tonet, nickname: self.currentNickname(), to: tochn, message: message }
		# Empty the message bar
		self.messageBar ""

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
		return
	return

window.interface = new InterfaceViewModel()

$(document).ready () ->
	ko.applyBindings window.interface