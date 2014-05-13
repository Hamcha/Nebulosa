var htmlEntities = function(str) {
    str = str.replace(/&/g, '&');
    str = str.replace(/</g, '<');
    str = str.replace(/>/g, '>');
    str = str.replace(/"/g, '"');
    return str;
};

var cmdrpl = {
	"msg": "PRIVMSG"
};

var makeCommand = function (message) {
	var parts = message.split(" ");
	// Check command for replacement
	parts[0] = parts[0].substr(1).toLowerCase();
	if (parts[0] in cmdrpl)
		parts[0] = cmdrpl[parts[0]];
	// Join and submit
	return {
		"Command" : parts.splice(0,1)[0],
		"Target"  : (parts.length > 0) ? parts.splice(0,1)[0] : "",
		"Text"    : parts.join(" ")
	};
};