window.filterSingle = (array, func) -> return {id:i,elem:x} for x,i in array when func x

window.ifval = (val, def) -> return if val? then val else def

window.scrollBottom = () -> $("#centerbar").scrollTop $("#centerbar > ul").height()

window.toTimeStr = (time) -> time + " seconds"

window.formatTime = (date) -> 
	time = new Date(date)
	("0"+time.getHours()).slice(-2)+":"+("0"+time.getMinutes()).slice(-2)+":"+("0"+time.getSeconds()).slice(-2)

sum = (chr,x) -> if x < 1 then 0 else (chr.charCodeAt x-1) + sum chr, (x-1)

hslToRgb = (h, s, l) ->
	if s == 0
		r = g = b = l
	else
		hue2rgb = (p, q, t) ->
			t += 1 if t < 0
			t -= 1 if t > 1
			return p + (q - p) * 6 * t if t < 1/6
			return q if t < 1/2
			return p + (q - p) * (2/3 - t) * 6 if t < 2/3
			return p
		q = if l < 0.5 then l * (1 + s) else l + s - l * s
		p = 2 * l - q
		r = hue2rgb p, q, h + 1/3
		g = hue2rgb p, q, h
		b = hue2rgb p, q, h - 1/3
	return [r * 255, g * 255, b * 255]

window.colorNick = (nick) ->
	ordVal = ((sum nick, nick.length) + 300) % 256
	lumC = ((sum nick, nick.length) + 631) % 100
	cVals = hslToRgb ordVal/256, 0.9, 0.2+lumC/500
	# Get hex values
	outRed = (Math.floor cVals[0]).toString 16
	outGrn = (Math.floor cVals[1]).toString 16
	outBlu = (Math.floor cVals[2]).toString 16
	# Pad numbers
	if outRed.length < 2 then outRed = "0" + outRed
	if outGrn.length < 2 then outGrn = "0" + outGrn
	if outBlu.length < 2 then outBlu = "0" + outBlu
	# Return custom value
	return "#"+outRed+outGrn+outBlu

window.htmlEntities = (str) ->
	str = str.replace /&/g, '&amp;'
	str = str.replace /</g, '&lt;'
	str = str.replace />/g, '&gt;'
	str = str.replace /"/g, '&quot;'
	return String str