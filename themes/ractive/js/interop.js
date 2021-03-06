(function() {
  var command, createSocket, socket;

  socket = void 0;

  createSocket = function(user, pass) {
    document.cookie = "user=" + user;
    document.cookie = "pass=" + pass;
    socket = io.connect('http://' + location.host);
    socket.on('error', function(data) {
      if (data === "handshake unauthorized") {
        document.cookie = "user=; expires=Thu, 01 Jan 1970 00:00:01 GMT;";
        document.cookie = "pass=; expires=Thu, 01 Jan 1970 00:00:01 GMT;";
        return window["interface"].AuthError();
      } else {
        return window["interface"].Exception("Connection has been lost..", true);
      }
    });
    socket.on('networks', function(data) {
      return window["interface"].initNetworks(data);
    });
    socket.on('buffers', function(flag) {
      return window["interface"].bufferMode = flag;
    });
    socket.on('message', function(data) {
      return window["interface"].addMessage(data);
    });
    socket.on('notice', function(data) {
      return window["interface"].addNotice(data);
    });
    socket.on('whois', function(data) {
      return window["interface"].addWhois(data);
    });
    socket.on('join', function(data) {
      return window["interface"].addChannelAction("join", data);
    });
    socket.on('part', function(data) {
      return window["interface"].addChannelAction("part", data);
    });
    socket.on('kick', function(data) {
      return window["interface"].addChannelAction("kick", data);
    });
    socket.on('mode', function(data) {
      return window["interface"].addChannelAction("mode", data);
    });
    socket.on('nick', function(data) {
      return window["interface"].addChannelAction("nick", data);
    });
    socket.on('quit', function(data) {
      return window["interface"].addChannelAction("quit", data);
    });
    socket.on('names', function(data) {
      return window["interface"].updateChannelUsers(data);
    });
    socket.on('chaninfo', function(data) {
      return window["interface"].updateChannelInfo(data);
    });
    socket.on('topic', function(data) {
      return window["interface"].setTopic(data);
    });
    socket.on('ircerror', function(data) {
      return window["interface"].addError(data.message.args.join(" "));
    });
    socket.on('disconnected', function(data) {
      return window["interface"].addChannelAction("disconnected", data);
    });
    return interop.socket = socket;
  };

  command = Object.create(null);

  command.join = function(net, chan, nick, args) {
    if (args[0] == null) {
      return false;
    }
    return socket.emit("join", {
      network: net,
      channel: args[0]
    });
  };

  command.part = function(net, chan, nick, args) {
    var pchan;
    pchan = args[0] != null ? args[0] : chan;
    return socket.emit("part", {
      network: net,
      channel: pchan
    });
  };

  command.nick = function(net, chan, nick, args) {
    var chanlist;
    if (args[0] == null) {
      return false;
    }
    chanlist = Object.keys(window["interface"].networks()[net].chans);
    return socket.emit("nick", {
      network: net,
      nickname: nick,
      newnick: args[0],
      channels: chanlist
    });
  };

  command.kick = function(net, chan, nick, args) {
    var reas, who;
    if (args.length < 2) {
      return false;
    }
    chan = args.splice(0, 1);
    who = args.splice(0, 1);
    reas = ifval(args.join(" ", who));
    return socket.emit("kick", {
      network: net,
      nickname: nick,
      channel: chan.toString(),
      nick: who.toString(),
      message: reas
    });
  };

  command.whois = function(net, chan, nick, args) {
    if (args[0] == null) {
      return false;
    }
    return socket.emit("whois", {
      network: net,
      nickname: args[0]
    });
  };

  command.quit = function(net, chan, nick, args) {
    var quitmsg;
    quitmsg = ifval(args[0], "Nebulosa IRC Client");
    return socket.emit("quitirc", {
      network: net,
      message: quitmsg
    });
  };

  command.connect = function(net, chan, nick, args) {
    return socket.emit("connect", {
      network: net
    });
  };

  command.msg = function(net, chan, nick, args) {
    var msg;
    if (args.length < 2) {
      return false;
    }
    chan = args.splice(0, 1);
    msg = args.join(" ");
    socket.emit("message", {
      network: net,
      nickname: nick,
      channel: chan.toString(),
      message: msg
    });
    window["interface"].messageBar("");
    return window["interface"].addMessage({
      network: net,
      nickname: nick,
      channel: chan.toString(),
      message: msg,
      time: +(new Date)
    });
  };

  command.notice = function(net, chan, nick, args) {
    var msg;
    if (args.length < 2) {
      return false;
    }
    chan = args.splice(0, 1);
    msg = args.join(" ");
    socket.emit("notice", {
      network: net,
      nickname: nick,
      channel: chan.toString(),
      message: msg
    });
    window["interface"].addNotice({
      network: net,
      nickname: nick,
      channel: chan.toString(),
      message: msg,
      time: +(new Date)
    });
    return window["interface"].messageBar("");
  };

  command.topic = function(net, chan, nick, args) {
    var msg;
    if (args.length < 2) {
      return false;
    }
    chan = args.splice(0, 1);
    msg = args.join(" ");
    return socket.emit("topic", {
      network: net,
      nickname: nick,
      channel: chan.toString(),
      topic: msg
    });
  };

  command.mode = function(net, chan, nick, args) {
    var what, who;
    if (args.length < 2) {
      return false;
    }
    chan = args.splice(0, 1);
    what = args.splice(0, 1);
    if (args.length > 0) {
      who = args.join(" ");
    }
    return socket.emit("mode", {
      network: net,
      nickname: nick,
      channel: chan.toString(),
      what: what,
      who: who
    });
  };

  command.raw = function(net, chan, nick, args) {
    if (args.length < 1) {
      return false;
    }
    return socket.emit("raw", {
      network: net,
      args: args
    });
  };

  window.interop = {
    createSocket: createSocket,
    socket: socket,
    command: command
  };

}).call(this);
