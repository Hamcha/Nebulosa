// Generated by CoffeeScript 1.6.3
(function() {
  var socket;

  socket = io.connect('http://' + location.host);

  socket.on('message', function(data) {
    return console.log(data);
  });

}).call(this);