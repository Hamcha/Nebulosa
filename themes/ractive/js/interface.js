(function() {
  var Channel, Interface, User, checkNotifications, currentMessage, lastIndex, showNotification, wordComplete;

  Channel = function(cdata) {
    this.created = cdata.created;
    this.key = cdata.key;
    this.isquery = false;
    this.unread = 0;
    this.mentioned = false;
    this.serverName = cdata.serverName;
    this.mode = cdata.mode;
    if (cdata.topic != null) {
      this.topic = cdata.topic;
    }
    if (cdata.topicBy != null) {
      this.topicBy = cdata.topicBy;
    }
  };

  User = function(nick, val) {
    this.nick = nick;
    this.val = val;
  };

  Interface = Ractive.extend({
    data: {
      networks: {},
      currentNetwork: "",
      currentChannel: "",
      userlist: {},
      messages: {},
      isChannel: true,
      bufferMode: false
    },
    netNickname: function(network) {
      var curnet, nets;
      curnet = this.get("currentNetwork");
      nets = this.get("networks." + curnet);
      if (nets != null) {
        return nets.nickname;
      } else {
        return null;
      }
    },
    addMessage: function(data) {
      var m, mentioned, nets, omitnick;
      nets = this.get("networks");
      if (data.channel === this.netNickname(data.network) || data.channel === data.nickname) {
        if (nets[data.network].chans[data.nickname] == null) {
          nets[data.network].chans[data.nickname] = new Channel({
            key: data.nickname,
            id: data.nickname
          });
          nets[data.network].chans[data.nickname].isquery = true;
          this.set("networks", nets);
        }
        data.channel = data.nickname;
      }
      if (this.get("messages." + data.network + "." + data.channel) == null) {
        this.set("messages." + data.network + "." + data.channel, []);
      }
      m = this.get("messages." + data.network + "." + data.channel);
      if (m[m.length - 1] != null) {
        if (m[m.length - 1].user === data.nickname) {
          omitnick = true;
        }
      }
      mentioned = data.message.indexOf(this.netNickname(data.network)) >= 0;
      m;
      this.get("messages." + data.network + "." + data.channel).push({
        type: "message",
        shownick: omitnick == null,
        user: data.nickname,
        message: this.processMessage(data.message),
        timestamp: formatTime(data.time),
        mentioned: mentioned
      });
      if (this.get("bufferMode") || data.channel === data.nickname) {
        return;
      }
      if (data.network !== this.currentNetwork() || data.channel !== this.currentChannel()) {
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
    },
    addNotice: function(data) {
      var chan, net;
      net = data.network;
      if (!this.get("bufferMode") && data.network === this.get("currentNetwork") && (data.nickname != null) && data.nickname !== "" && servernicks.indexOf(data.nickname.toLowerCase()) < 0 && data.channel !== "*") {
        chan = this.get("currentChannel");
      } else {
        chan = ":status";
      }
      if (this.get("messages." + net + "." + chan) == null) {
        this.set("messages." + net + "." + chan, []);
      }
      this.get("messages." + net + "." + chan).push({
        type: "notice",
        channel: data.channel,
        user: data.nickname,
        message: this.processMessage(data.message),
        timestamp: formatTime(data.time)
      });
      if (chan === ":status") {
        this.get("networks." + net).unread += 1;
      }
      return scrollBottom();
    },
    addChannelAction: function(type, data) {
      var chan, channels, indexChan, indexUser, modesym, nets, reason, uindex, ulist, ustring, uvals, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2;
      switch (type) {
        case "join":
          if (!this.get("bufferMode") && data.nickname === this.netNickname(data.network)) {
            interop.socket.emit("chaninfo", {
              network: data.network,
              channel: data.channel
            });
            return;
          }
          if (this.get("messages." + data.network + "." + data.channel) == null) {
            this.set("messages." + data.network + "." + data.channel, []);
          }
          this.get("messages." + data.network + "." + data.channel).push({
            type: "chaction",
            message: "<b>" + data.nickname + "</b>  has joined the channel",
            timestamp: formatTime(data.time)
          });
          if (this.get("bufferMode")) {
            break;
          }
          this.get("userlist." + data.network + "." + data.channel).push(new User(data.nickname, ""));
          break;
        case "part":
        case "kick":
        case "quit":
          if (!this.get("bufferMode") && data.nickname === this.netNickname(data.network)) {
            this.switchTo(data.network, ":status", false);
            nets = this.networks();
            delete nets[data.network].chans[data.channel];
            this.networks(nets);
            return;
          }
          data.reason = ifval(data.reason, "");
          switch (type) {
            case "part":
              if (this.get("messages." + data.network + "." + data.channel) == null) {
                this.set("messages." + data.network + "." + data.channel, []);
              }
              this.get("messages." + data.network + "." + data.channel).push({
                type: "chaction",
                message: "<b>" + data.nickname + "</b>  has left the channel (" + data.reason + ")",
                timestamp: formatTime(data.time)
              });
              break;
            case "kick":
              if (this.get("messages." + data.network + "." + data.channel) == null) {
                this.set("messages." + data.network + "." + data.channel, []);
              }
              this.get("messages." + data.network + "." + data.channel).push({
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
                if (this.messages[data.network + "." + chan] == null) {
                  this.messages[data.network + "." + chan] = [];
                }
                this.messages[data.network + "." + chan].push({
                  type: "chaction",
                  message: "<b>" + data.nickname + "</b> has quit (" + reason + ")",
                  timestamp: formatTime(data.time)
                });
              }
          }
          if (this.get("bufferMode")) {
            break;
          }
          ulist = this.userlist();
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
            this.userlist(ulist);
          }
          break;
        case "mode":
          data.by = ifval(data.by, data.network);
          if ((data.argument != null) && (modeSymbol[data.mode] != null) && !this.get("bufferMode")) {
            ulist = this.userlist();
            indexChan = data.network + "." + data.channel;
            indexUser = filterSingle(ulist[indexChan], function(x) {
              return x.nick() === data.argument;
            });
            if (indexUser.id >= 0) {
              modesym = modeSymbol[data.mode];
              ustring = ulist[indexChan][indexUser.id].val();
              if (data.what === "+") {
                ustring += modesym;
                ustring = ustring.split("").sort(this.modeSort).join("");
              } else {
                if (uindex >= 0) {
                  uindex = ustring.indexOf(modesym);
                }
                uvals = ustring.split("");
                uvals.splice(uindex, 1);
                ustring = uvals.join("");
              }
              ulist[indexChan][indexUser.id].val(ustring);
              this.userlist(ulist);
            }
          }
          if (data.argument == null) {
            data.argument = "";
          }
          if (this.get("messages." + data.network + "." + data.channel) == null) {
            this.set("messages." + data.network + "." + data.channel, []);
          }
          this.get("messages." + data.network + "." + data.channel).push({
            type: "chaction",
            message: "<b>" + data.by + "</b>  sets mode " + data.what + data.mode + " " + data.argument,
            timestamp: formatTime(data.time)
          });
          break;
        case "nick":
          if (!this.get("bufferMode") && data.oldnick === this.netNickname(data.network)) {
            nets = this.networks();
            nets[data.network].nickname = data.newnick;
            this.networks(nets);
          }
          if (!Array.isArray(data.channels)) {
            data.channels = [data.channels];
          }
          _ref1 = data.channels;
          for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
            chan = _ref1[_k];
            if (this.get("messages." + data.network + "." + chan) == null) {
              this.set("messages." + data.network + "." + chan, []);
            }
            this.get("messages." + data.network + "." + chan).push({
              type: "chaction",
              message: "<b>" + data.oldnick + "</b> is now <b>" + data.newnick + "</b>",
              timestamp: formatTime(data.time)
            });
          }
          if (this.get("bufferMode")) {
            break;
          }
          ulist = this.userlist();
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
          this.userlist(ulist);
          break;
        case "quit":
          this.switchTo(data.network, ":status", false);
          this.messages[data.network + ".:status"].push({
            type: "chaction",
            message: "Disconnected from <b>" + data.network + "</b>",
            timestamp: formatTime(data.time)
          });
      }
      return scrollBottom();
    },
    processMessage: function(message) {
      message = htmlEntities(message);
      message = linkify(message);
      return message;
    },
    updateChannelInfo: function(data) {
      this.updateChannelUsers({
        network: data.network,
        channel: data.channeldata.key,
        nicks: data.channeldata.users
      });
      this.set("networks." + data.network + ".chans." + data.channeldata.key, new Channel(data.channeldata));
      this.set("isChannel", true);
      this.set("currentNetwork", data.network);
      return this.set("currentChannel", data.channeldata.key);
    },
    updateChannelUsers: function(data) {
      var ulist, uname, uval;
      ulist = (function() {
        var _ref, _results;
        _ref = data.nicks;
        _results = [];
        for (uname in _ref) {
          uval = _ref[uname];
          _results.push(new User(uname, uval));
        }
        return _results;
      })();
      return this.set("userlist." + data.network + "." + data.channel, ulist);
    },
    initNetworks: function(data) {
      var chan, chanobjs, cid, cname, cval, network, nid, _ref, _ref1;
      for (nid in data) {
        network = data[nid];
        _ref = network.chans;
        for (cname in _ref) {
          cval = _ref[cname];
          this.updateChannelUsers({
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
      this.set("networks", data);
      this.set("currentNetwork", Object.keys(data)[0]);
      this.set("currentChannel", Object.keys(data[Object.keys(data)[0]].chans)[0].key);
    }
  });

  window.servernicks = ["infoserv", "global"];

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

  currentMessage = "";

  $(document).ready(function() {
    window["interface"] = new Interface({
      el: 'container',
      template: '#template'
    });
    window["interface"].on('sendMessage', function(event) {
      return event.original.preventDefault();
    });
    window["interface"].observe('messageBar', function(val) {
      return currentMessage = val;
    });
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
    return $("#inputbarcont").on("keydown", '#inputbar', function(event) {
      var chan, keyCode, net, users, words;
      keyCode = event.keyCode || event.which;
      if (keyCode === 9) {
        event.preventDefault();
        words = $("#inputbar").val().split(" ");
        if (window["interface"].get('isChannel')) {
          net = window["interface"].get("currentNetwork");
          chan = window["interface"].get("currentChannel");
          if (wordComplete === null) {
            wordComplete = words[words.length - 1];
          }
          users = window["interface"].get("userlist." + net + "." + chan).filter(function(elem) {
            return elem.nick.toLowerCase().indexOf(wordComplete.toLowerCase()) === 0;
          });
          if (lastIndex >= users.length) {
            lastIndex = 0;
          }
          words[words.length - 1] = users[lastIndex].nick;
          lastIndex++;
        } else {
          words[words.length - 1] = window["interface"].get("currentChannel");
        }
        return currentMessage = words.join(" ");
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
