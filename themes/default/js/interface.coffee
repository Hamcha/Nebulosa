InterfaceViewModel = () ->
	self = this

	# Network and channel list
	self.networks = ko.observableArray []
	self.currentNetwork = ko.observable "ponychat"
	self.currentChannel = ko.observable "#testbass"
	self.userlist = ko.observable {}
	self.messages = ko.observable {}

	# Get the user list for the active channel
	self.channelUsers = ko.computed () -> self.userlist()[self.currentNetwork()+self.currentChannel()]

	# Get the activity for the active channel
	self.channelActivity = ko.computed () -> self.messages()[self.currentNetwork()+self.currentChannel()]

	# Add message to list
	self.addMessage = (data) ->
		msgs = self.messages()
		if !msgs[data.network+data.to]?
			msgs[data.network+data.to] = []
		msgs[data.network+data.to].push { user: data.nickname, message: data.message }
		self.messages msgs

	# Get the networks and channels joined and format them so they can be loaded into Knockout
	self.initNetworks = (data) ->
		tdata = []
		udata = {}
		# Put networks on array structure
		for nid,network of data
			tnet = {}
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