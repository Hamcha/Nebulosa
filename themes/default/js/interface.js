// Generated by CoffeeScript 1.6.3
(function() {
  var InterfaceViewModel;

  InterfaceViewModel = function() {
    var self;
    self = this;
    self.networks = ko.observableArray([]);
    self.currentNetwork = ko.observable("ponychat");
    self.currentChannel = ko.observable("#testbass");
    self.userlist = ko.observable({});
    self.messages = ko.observable({});
    self.channelUsers = ko.computed(function() {
      return self.userlist()[self.currentNetwork() + self.currentChannel()];
    });
    self.channelActivity = ko.computed(function() {
      return self.messages()[self.currentNetwork() + self.currentChannel()];
    });
    self.addMessage = function(data) {
      var msgs;
      msgs = self.messages();
      if (msgs[data.network + data.to] == null) {
        msgs[data.network + data.to] = [];
      }
      msgs[data.network + data.to].push({
        user: data.nickname,
        message: data.message
      });
      return self.messages(msgs);
    };
    self.initNetworks = function(data) {
      var cname, cval, network, nid, tdata, tnet, uchan, udata, uname, uval, _ref, _ref1;
      tdata = [];
      udata = {};
      for (nid in data) {
        network = data[nid];
        tnet = {};
        tnet.name = network.name;
        tnet.id = nid;
        tnet.chans = [];
        _ref = network.chans;
        for (cname in _ref) {
          cval = _ref[cname];
          cval.id = cname;
          tnet.chans.push(cval);
          uchan = [];
          _ref1 = cval.users;
          for (uname in _ref1) {
            uval = _ref1[uname];
            uchan.push(uname);
          }
          udata[tnet.id + cname] = uchan;
        }
        tdata.push(tnet);
      }
      self.networks(tdata);
      self.userlist(udata);
    };
  };

  window["interface"] = new InterfaceViewModel();

  $(document).ready(function() {
    return ko.applyBindings(window["interface"]);
  });

}).call(this);