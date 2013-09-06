// Generated by CoffeeScript 1.6.3
(function() {
  window.filterSingle = function(array, func) {
    var i, x, _i, _len;
    for (i = _i = 0, _len = array.length; _i < _len; i = ++_i) {
      x = array[i];
      if (func(x)) {
        return {
          id: i,
          elem: x
        };
      }
    }
  };

  window.scrollBottom = function() {
    return $("#centerbar").animate({
      scrollTop: $("#centerbar").height()
    }, "fast");
  };

  window.formatTime = function(date) {
    var time;
    time = new Date(date);
    return ("0" + time.getHours()).slice(-2) + ":" + ("0" + time.getMinutes()).slice(-2) + ":" + ("0" + time.getSeconds()).slice(-2);
  };

}).call(this);
