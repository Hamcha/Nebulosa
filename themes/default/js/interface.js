(function() {
  var Channel, InterfaceViewModel, User, checkNotifications, lastIndex, showNotification, wordComplete;

  Channel = function(cdata) {
    this.created = cdata.created;
    this.key = cdata.key;
    this.isquery = false;
    this.unread = ko.observable(0);
    this.mentioned = ko.observable(false);
    this.serverName = cdata.serverName;
    this.mode = ko.observable(cdata.mode);
    if (cdata.topic != null) {
      this.topic = cdata.topic;
    }
    if (cdata.topicBy != null) {
      this.topicBy = cdata.topicBy;
    }
  };

  User = function(nick, val) {
    this.nick = ko.observable(nick);
    this.val = ko.observable(val);
  };

  InterfaceViewModel = function() {
    var self;
    self = this;
    self.networks = ko.observable({});
    self.currentNetwork = ko.observable("");
    self.currentChannel = ko.observable("");
    self.messageBar = ko.observable("");
    self.userlist = ko.observable({});
    self.messages = {};
    self.isChannel = true;
    self.bufferMode = false;
    self.networkList = ko.computed(function() {
      var cname, cval, network, nid, tdata, tnet, uchan, udata, uname, uval, _ref, _ref1, _ref2;
      tdata = [];
      udata = {};
      _ref = self.networks();
      for (nid in _ref) {
        network = _ref[nid];
        tnet = {};
        tnet.nickname = network.nickname;
        tnet.name = network.name;
        tnet.id = nid;
        tnet.chans = [];
        _ref1 = network.chans;
        for (cname in _ref1) {
          cval = _ref1[cname];
          cval.id = cname;
          cval.unread();
          cval.messages = ifval(self.messages[tnet.id + "." + cname], []);
          tnet.chans.push(cval);
          uchan = [];
          _ref2 = cval.users;
          for (uname in _ref2) {
            uval = _ref2[uname];
            uchan.push(uname);
          }
          udata[tnet.id + cname] = uchan;
        }
        tdata.push(tnet);
      }
      return tdata;
    });
    self.channelUsers = ko.computed(function() {
      var ulist;
      ulist = self.userlist()[self.currentNetwork() + "." + self.currentChannel()];
      if (ulist == null) {
        return;
      }
      ulist.sort(self.nickSort);
      return ulist;
    });
    self.currentTopic = ko.computed(function() {
      var curchan, curnet, nets, tnick, topic;
      nets = self.networks();
      curnet = self.currentNetwork();
      curchan = self.currentChannel();
      if (!(self.isChannel && nets !== [] && curnet !== "" && curchan !== "" && (nets[curnet].chans[curchan] != null))) {
        return false;
      }
      topic = nets[curnet].chans[curchan].topic;
      tnick = nets[curnet].chans[curchan].topicBy;
      if (topic != null) {
        return {
          topic: topic,
          topicBy: tnick
        };
      } else {
        return false;
      }
    });
    self.currentNickname = ko.computed(function() {
      var curnet, nets;
      curnet = self.currentNetwork();
      nets = self.networks()[curnet];
      if (nets != null) {
        return nets.nickname;
      } else {
        return null;
      }
    });
    self.netNickname = function(network) {
      var curnet, nets;
      curnet = self.currentNetwork();
      nets = self.networks()[curnet];
      if (nets != null) {
        return nets.nickname;
      } else {
        return null;
      }
    };
    self.addMessage = function(data) {
      var m, mentioned, nets, omitnick;
      nets = self.networks();
      if (data.channel === self.netNickname(data.network) || data.channel === data.nickname) {
        if (nets[data.network].chans[data.nickname] == null) {
          nets[data.network].chans[data.nickname] = new Channel({
            key: data.nickname,
            id: data.nickname
          });
          nets[data.network].chans[data.nickname].isquery = true;
          self.networks(nets);
        }
        data.channel = data.nickname;
      }
      if (self.messages[data.network + "." + data.channel] == null) {
        self.messages[data.network + "." + data.channel] = ko.observableArray();
      }
      m = self.messages[data.network + "." + data.channel]();
      if (m[m.length - 1] != null) {
        if (m[m.length - 1].user === data.nickname) {
          omitnick = true;
        }
      }
      mentioned = data.message.indexOf(self.netNickname(data.network)) >= 0;
      self.messages[data.network + "." + data.channel].push({
        type: "message",
        shownick: omitnick == null,
        user: data.nickname,
        message: self.processMessage(data.message),
        timestamp: formatTime(data.time),
        mentioned: mentioned
      });
      self.networks(nets);
      if (self.bufferMode || data.channel === data.nickname) {
        return;
      }
      if (data.network !== self.currentNetwork() || data.channel !== self.currentChannel()) {
        nets[data.network].chans[data.channel].unread(nets[data.network].chans[data.channel].unread() + 1);
        if (mentioned) {
          nets[data.network].chans[data.channel].mentioned(true);
          if (window.notifications) {
            return showNotification("Mentioned!", data.nickname + " mentioned you on " + data.channel + "!");
          }
        }
      } else {
        return scrollBottom();
      }
    };
    self.addNotice = function(data) {
      var chan, net, nets;
      net = data.network;
      if (!self.bufferMode && data.network === self.currentNetwork() && (data.nickname != null) && data.nickname !== "" && servernicks.indexOf(data.nickname.toLowerCase()) < 0 && data.channel !== "*") {
        chan = self.currentChannel();
      } else {
        chan = ":status";
      }
      if (self.messages[net + "." + chan] == null) {
        self.messages[net + "." + chan] = ko.observableArray();
      }
      self.messages[net + "." + chan].push({
        type: "notice",
        channel: data.channel,
        user: data.nickname,
        message: self.processMessage(data.message),
        timestamp: formatTime(data.time)
      });
      if (chan === ":status") {
        nets = self.networks();
        nets[data.network].unread += 1;
      }
      return scrollBottom();
    };
    self.addChannelAction = function(type, data) {
      var chan, channels, indexChan, indexUser, modesym, nets, reason, uindex, ulist, ustring, uvals, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2;
      switch (type) {
        case "join":
          if (!self.bufferMode && data.nickname === self.netNickname(data.network)) {
            interop.socket.emit("chaninfo", {
              network: data.network,
              channel: data.channel
            });
            return;
          }
          if (self.messages[data.network + "." + data.channel] == null) {
            self.messages[data.network + "." + data.channel] = ko.observableArray();
          }
          self.messages[data.network + "." + data.channel].push({
            type: "chaction",
            message: "<b>" + data.nickname + "</b>  has joined the channel",
            timestamp: formatTime(data.time)
          });
          if (self.bufferMode) {
            break;
          }
          ulist = self.userlist();
          ulist[data.network + "." + data.channel].push(new User(data.nickname, ""));
          self.userlist(ulist);
          break;
        case "part":
        case "kick":
        case "quit":
          if (!self.bufferMode && data.nickname === self.netNickname(data.network)) {
            self.switchTo(data.network, ":status", false);
            nets = self.networks();
            delete nets[data.network].chans[data.channel];
            self.networks(nets);
            return;
          }
          data.reason = ifval(data.reason, "");
          switch (type) {
            case "part":
              if (self.messages[data.network + "." + data.channel] == null) {
                self.messages[data.network + "." + data.channel] = ko.observableArray();
              }
              self.messages[data.network + "." + data.channel].push({
                type: "chaction",
                message: "<b>" + data.nickname + "</b>  has left the channel (" + data.reason + ")",
                timestamp: formatTime(data.time)
              });
              break;
            case "kick":
              if (self.messages[data.network + "." + data.channel] == null) {
                self.messages[data.network + "." + data.channel] = ko.observableArray();
              }
              self.messages[data.network + "." + data.channel].push({
                type: "chaction",
                message: "<b>" + data.nickname + "</b>  has been kicked by <b>" + data.by + "</b> (" + data.reason + ")",
                timestamp: formatTime(data.time)
              });
              break;
            case "quit":
              if (!Array.isArray(data.channels)) {
                data.channels = [data.channels];
              }
              reason = ifval(data.reason, "");
              _ref = data.channels;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                chan = _ref[_i];
                if (self.messages[data.network + "." + chan] == null) {
                  self.messages[data.network + "." + chan] = ko.observableArray();
                }
                self.messages[data.network + "." + chan].push({
                  type: "chaction",
                  message: "<b>" + data.nickname + "</b> has quit (" + reason + ")",
                  timestamp: formatTime(data.time)
                });
              }
          }
          if (self.bufferMode) {
            break;
          }
          ulist = self.userlist();
          if (type !== "quit") {
            channels = [data.channel];
          } else {
            channels = data.channels;
          }
          for (_j = 0, _len1 = channels.length; _j < _len1; _j++) {
            chan = channels[_j];
            indexChan = data.network + "." + chan;
            indexUser = filterSingle(ulist[indexChan], function(x) {
              return x.nick() === data.nickname;
            });
            if (indexUser.id >= 0) {
              ulist[indexChan].splice(indexUser.id, 1);
            }
            self.userlist(ulist);
          }
          break;
        case "mode":
          data.by = ifval(data.by, data.network);
          if ((data.argument != null) && (modeSymbol[data.mode] != null) && !self.bufferMode) {
            ulist = self.userlist();
            indexChan = data.network + "." + data.channel;
            indexUser = filterSingle(ulist[indexChan], function(x) {
              return x.nick() === data.argument;
            });
            if (indexUser.id >= 0) {
              modesym = modeSymbol[data.mode];
              ustring = ulist[indexChan][indexUser.id].val();
              if (data.what === "+") {
                ustring += modesym;
                ustring = ustring.split("").sort(self.modeSort).join("");
              } else {
                if (uindex >= 0) {
                  uindex = ustring.indexOf(modesym);
                }
                uvals = ustring.split("");
                uvals.splice(uindex, 1);
                ustring = uvals.join("");
              }
              ulist[indexChan][indexUser.id].val(ustring);
              self.userlist(ulist);
            }
          }
          if (data.argument == null) {
            data.argument = "";
          }
          if (self.messages[data.network + "." + data.channel] == null) {
            self.messages[data.network + "." + data.channel] = ko.observableArray();
          }
          self.messages[data.network + "." + data.channel].push({
            type: "chaction",
            message: "<b>" + data.by + "</b>  sets mode " + data.what + data.mode + " " + data.argument,
            timestamp: formatTime(data.time)
          });
          break;
        case "nick":
          if (!self.bufferMode && data.oldnick === self.netNickname(data.network)) {
            nets = self.networks();
            nets[data.network].nickname = data.newnick;
            self.networks(nets);
          }
          if (!Array.isArray(data.channels)) {
            data.channels = [data.channels];
          }
          _ref1 = data.channels;
          for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
            chan = _ref1[_k];
            if (self.messages[data.network + "." + chan] == null) {
              self.messages[data.network + "." + chan] = ko.observableArray();
            }
            self.messages[data.network + "." + chan].push({
              type: "chaction",
              message: "<b>" + data.oldnick + "</b> is now <b>" + data.newnick + "</b>",
              timestamp: formatTime(data.time)
            });
          }
          if (self.bufferMode) {
            break;
          }
          ulist = self.userlist();
          _ref2 = data.channels;
          for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
            chan = _ref2[_l];
            indexChan = data.network + "." + chan;
            indexUser = filterSingle(ulist[indexChan], function(x) {
              return x.nick() === data.oldnick;
            });
            if (indexUser.id >= 0) {
              ulist[indexChan][indexUser.id].nick(data.newnick);
            }
          }
          self.userlist(ulist);
          break;
        case "quit":
          self.switchTo(data.network, ":status", false);
          self.messages[data.network + ".:status"].push({
            type: "chaction",
            message: "Disconnected from <b>" + data.network + "</b>",
            timestamp: formatTime(data.time)
          });
      }
      return scrollBottom();
    };
    self.addError = function(message) {
      var curchan, curnet;
      curchan = self.currentChannel();
      curnet = self.currentNetwork();
      if (self.messages[curnet + "." + curchan] == null) {
        self.messages[curnet + "." + curchan] = ko.observableArray();
      }
      self.messages[curnet + "." + curchan].push({
        type: "error",
        user: "",
        message: message
      });
      return scrollBottom();
    };
    self.addWhois = function(data) {
      var curchan, curnet, ninfo;
      curchan = self.currentChannel();
      curnet = self.currentNetwork();
      if (self.messages[curnet + "." + curchan] == null) {
        self.messages[curnet + "." + curchan] = ko.observableArray();
      }
      ninfo = ["<b>" + data.info.nick + "</b> is " + data.info.realname + " (" + data.info.user + "@" + data.info.host + ")", "&nbsp;&nbsp;&nbsp;&nbsp;is on <b>" + (data.info.channels.join(", ")) + "</b>", "&nbsp;&nbsp;&nbsp;&nbsp;is on " + data.info.server + " (" + data.info.serverinfo + ")"];
      if (data.info.idle != null) {
        ninfo.push("&nbsp;&nbsp;&nbsp;&nbsp;has been idle " + toTimeStr(data.info.idle));
      }
      self.messages[curnet + "." + curchan].push({
        type: "whois",
        user: "",
        nickname: data.info.nick,
        info: ninfo
      });
      return scrollBottom();
    };
    self.processMessage = function(message) {
      message = htmlEntities(message);
      message = linkify(message);
      return message;
    };
    self.sendMessage = function() {
      var action, curnick, message, parts, tochn, tonet;
      tonet = self.currentNetwork();
      tochn = self.currentChannel();
      curnick = self.currentNickname();
      message = self.messageBar();
      if (message[0] === "/" && (message[1] != null) && message[1] !== "/") {
        parts = message.substring(1).split(" ");
        action = parts.splice(0, 1);
        if (interop.command[action] == null) {
          self.addError("Unsupported command (" + action + ")");
        } else {
          interop.command[action](tonet, tochn, curnick, parts);
        }
      } else {
        message = message.replace(/^\/\//, "/");
        if (message === "") {
          return;
        }
        interop.socket.emit("message", {
          network: tonet,
          channel: tochn,
          message: message,
          nickname: curnick
        });
        self.addMessage({
          network: tonet,
          nickname: self.currentNickname(),
          channel: tochn,
          message: message,
          time: +(new Date)
        });
      }
      return self.messageBar("");
    };
    self.switchTo = function(network, channel, isChannel) {
      var nets;
      if (self.isChannel !== isChannel) {
        if (isChannel) {
          $("#rightbar").removeClass("hiddenbar");
          $("#centerbar").removeClass("superwide");
          $("#centerbar").addClass("normalwide");
        } else {
          $("#rightbar").addClass("hiddenbar");
          $("#centerbar").removeClass("normalwide");
          $("#centerbar").addClass("superwide");
        }
        self.isChannel = isChannel;
      }
      self.currentNetwork(network);
      self.currentChannel(channel);
      scrollBottom();
      if (channel !== ":status") {
        nets = self.networks();
        nets[network].chans[channel].unread(0);
        nets[network].chans[channel].mentioned(false);
        return self.networks(nets);
      }
    };
    self.updateChannelInfo = function(data) {
      var nets;
      nets = self.networks();
      self.updateChannelUsers({
        network: data.network,
        channel: data.channeldata.key,
        nicks: data.channeldata.users
      });
      nets[data.network].chans[data.channeldata.key] = new Channel(data.channeldata);
      self.networks(nets);
      self.isChannel = true;
      self.currentNetwork(data.network);
      return self.currentChannel(data.channeldata.key);
    };
    self.updateChannelUsers = function(data) {
      var indexChan, uchan, ulist, uname, uval, _ref;
      indexChan = data.network + "." + data.channel;
      ulist = self.userlist();
      uchan = [];
      _ref = data.nicks;
      for (uname in _ref) {
        uval = _ref[uname];
        uchan.push(new User(uname, uval));
      }
      ulist[indexChan] = uchan;
      return self.userlist(ulist);
    };
    self.setTopic = function(data) {
      var nets;
      nets = self.networks();
      if (nets[data.network].chans[data.channel] == null) {
        return;
      }
      nets[data.network].chans[data.channel].topic = data.topic;
      nets[data.network].chans[data.channel].topicBy = data.nickname;
      self.networks(nets);
      if (self.messages[data.network + "." + data.channel] == null) {
        self.messages[data.network + "." + data.channel] = ko.observableArray();
      }
      self.messages[data.network + "." + data.channel].push({
        type: "chaction",
        message: data.nickname + " has set the topic to: " + data.topic,
        timestamp: formatTime(data.time)
      });
      return scrollBottom();
    };
    self.initNetworks = function(data) {
      var chan, chanobjs, cid, cname, cval, nets, network, nid, _ref, _ref1;
      for (nid in data) {
        network = data[nid];
        _ref = network.chans;
        for (cname in _ref) {
          cval = _ref[cname];
          self.updateChannelUsers({
            network: nid,
            channel: cname,
            nicks: cval.users
          });
        }
        chanobjs = {};
        _ref1 = data[nid].chans;
        for (cid in _ref1) {
          chan = _ref1[cid];
          chanobjs[cid] = new Channel(chan);
        }
        data[nid].chans = chanobjs;
        data[nid].unread = 0;
      }
      self.networks(data);
      nets = self.networkList();
      if (nets[0] != null) {
        self.currentNetwork(nets[0].id);
      }
      if (nets[0].chans[0] != null) {
        self.currentChannel(nets[0].chans[0].key);
      }
    };
    self.nickSort = function(a, b) {
      if (a.val() === "" && b.val() !== "") {
        return 1;
      }
      if (b.val() === "" && a.val() !== "") {
        return -1;
      }
      if (b.val() !== a.val()) {
        if (modeOrder.indexOf(b.val()[0]) > modeOrder.indexOf(a.val()[0])) {
          return 1;
        }
        if (modeOrder.indexOf(b.val()[0]) < modeOrder.indexOf(a.val()[0])) {
          return -1;
        }
      }
      if (b.nick() < a.nick()) {
        return 1;
      }
      if (b.nick() > a.nick()) {
        return -1;
      }
      return 0;
    };
    self.modeSort = function(a, b) {
      return modeOrder.indexOf(a) - modeOrder.indexOf(b);
    };
    self.AuthError = function() {
      var modal;
      modal = new $.UIkit.modal.Modal("#autherr");
      return modal.show();
    };
    self.Exception = function(data, fatal) {
      var modal;
      if (fatal == null) {
        fatal = false;
      }
      $("#generrcnt").html("<h2>Oops..</h2><p>" + data + "</p>");
      modal = new $.UIkit.modal.Modal("#generr");
      if (fatal) {
        modal.options.bgclose = modal.options.keyboard = false;
      }
      return modal.show();
    };
    self.AuthDialog = function() {
      var pass, user;
      if (self.authdialog == null) {
        self.authdialog = new $.UIkit.modal.Modal("#authdlg");
      }
      self.authdialog.options.bgclose = self.authdialog.options.keyboard = false;
      self.authdialog.show();
      user = document.cookie.replace(/(?:(?:^|.*;\s*)user\s*\=\s*([^;]*).*$)|^.*$/, "$1");
      pass = document.cookie.replace(/(?:(?:^|.*;\s*)pass\s*\=\s*([^;]*).*$)|^.*$/, "$1");
      if (!(user !== "" || pass !== "")) {
        $("#autocred").hide();
      }
      if (user !== "") {
        $("#userauth").val(user);
      }
      if (pass !== "") {
        $("#pwdauth").val(pass);
      }
      return $("#userauth").focus();
    };
    self.auth = function(formdata) {
      formdata.username.className = formdata.username.value === "" ? "uk-form-danger" : "";
      formdata.password.className = formdata.password.value === "" ? "uk-form-danger" : "";
      if (formdata.password.value === "" || formdata.username.value === "") {
        return;
      }
      self.authdialog.hide();
      return interop.createSocket(formdata.username.value, formdata.password.value);
    };
  };

  window.servernicks = ["infoserv", "global"];

  window["interface"] = new InterfaceViewModel();

  window.modeOrder = "+%@&~";

  window.modeSymbol = {
    "v": "+",
    "h": "%",
    "o": "@",
    "a": "&",
    "q": "~"
  };

  window.notifications = false;

  wordComplete = null;

  lastIndex = 0;

  $(document).ready(function() {
    ko.applyBindings(window["interface"]);
    $("#linkNotify").on("click", function(e) {
      var notifies;
      if (window.webkitNotifications) {
        notifies = checkNotifications();
        if (notifies === 1) {
          window.webkitNotifications.requestPermission(checkNotifications);
        }
        if (notifies === 0) {
          return window.notifications = true;
        }
      }
    });
    $.get("/useAuth", function(data) {
      if (data === "true") {
        return window["interface"].AuthDialog();
      } else {
        return interop.createSocket();
      }
    });
    $("#autherr").on('uk.modal.hide', function() {
      return location.reload();
    });
    return $("#inputbarcont").on("keydown", '#inputbar', function(e) {
      var keyCode, users, words;
      keyCode = e.keyCode || e.which;
      if (keyCode === 9) {
        words = $("#inputbar").val().split(" ");
        if (window["interface"].isChannel) {
          if (wordComplete === null) {
            wordComplete = words[words.length - 1];
          }
          users = window["interface"].channelUsers().filter(function(elem) {
            return elem.nick().toLowerCase().indexOf(wordComplete.toLowerCase()) === 0;
          });
          if (lastIndex >= users.length) {
            lastIndex = 0;
          }
          words[words.length - 1] = users[lastIndex].nick();
          lastIndex++;
        } else {
          words[words.length - 1] = window["interface"].currentChannel();
        }
        window["interface"].messageBar(words.join(" "));
        return e.preventDefault();
      } else {
        if (wordComplete !== null) {
          return wordComplete = null;
        }
      }
    });
  });

  checkNotifications = function() {
    switch (window.webkitNotifications.checkPermission()) {
      case 0:
        window.notifications = true;
        return 0;
      case 1:
        return 1;
      case 2:
        window.notifications = false;
        return 2;
    }
  };

  showNotification = function(title, message) {
    var icon, notification;
    icon = "/images/icon32.png";
    notification = window.webkitNotifications.createNotification(icon, title, message);
    return notification.show();
  };

}).call(this);
