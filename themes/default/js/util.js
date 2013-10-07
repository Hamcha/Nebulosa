(function() {
  var hslToRgb, sum;

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

  window.ifval = function(val, def) {
    if (val != null) {
      return val;
    } else {
      return def;
    }
  };

  window.scrollBottom = function() {
    return $("#centerbar").scrollTop($("#centerbar > ul").height());
  };

  window.toTimeStr = function(time) {
    return time + " seconds";
  };

  window.formatTime = function(date) {
    var time;
    time = new Date(date);
    return ("0" + time.getHours()).slice(-2) + ":" + ("0" + time.getMinutes()).slice(-2) + ":" + ("0" + time.getSeconds()).slice(-2);
  };

  sum = function(chr, x) {
    if (x < 1) {
      return 0;
    } else {
      return (chr.charCodeAt(x - 1)) + sum(chr, x - 1);
    }
  };

  hslToRgb = function(h, s, l) {
    var b, g, hue2rgb, p, q, r;
    if (s === 0) {
      r = g = b = l;
    } else {
      hue2rgb = function(p, q, t) {
        if (t < 0) {
          t += 1;
        }
        if (t > 1) {
          t -= 1;
        }
        if (t < 1 / 6) {
          return p + (q - p) * 6 * t;
        }
        if (t < 1 / 2) {
          return q;
        }
        if (t < 2 / 3) {
          return p + (q - p) * (2 / 3 - t) * 6;
        }
        return p;
      };
      q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }
    return [r * 255, g * 255, b * 255];
  };

  window.colorNick = function(nick) {
    var cVals, lumC, ordVal, outBlu, outGrn, outRed;
    ordVal = ((sum(nick, nick.length)) + 300) % 256;
    lumC = ((sum(nick, nick.length)) + 631) % 100;
    cVals = hslToRgb(ordVal / 256, 0.9, 0.2 + lumC / 500);
    outRed = (Math.floor(cVals[0])).toString(16);
    outGrn = (Math.floor(cVals[1])).toString(16);
    outBlu = (Math.floor(cVals[2])).toString(16);
    if (outRed.length < 2) {
      outRed = "0" + outRed;
    }
    if (outGrn.length < 2) {
      outGrn = "0" + outGrn;
    }
    if (outBlu.length < 2) {
      outBlu = "0" + outBlu;
    }
    return "#" + outRed + outGrn + outBlu;
  };

  window.htmlEntities = function(str) {
    str = str.replace(/&/g, '&amp;');
    str = str.replace(/</g, '&lt;');
    str = str.replace(/>/g, '&gt;');
    str = str.replace(/"/g, '&quot;');
    return String(str);
  };

}).call(this);
