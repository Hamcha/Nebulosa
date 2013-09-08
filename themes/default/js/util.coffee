window.filterSingle = (array, func) -> return {id:i,elem:x} for x,i in array when func x
window.ifval = (val, def) -> return if val? then val else def
window.scrollBottom = () -> $("#centerbar").animate { scrollTop: $("#centerbar").height() }, "fast"

window.formatTime = (date) -> 
	time = new Date(date)
	("0"+time.getHours()).slice(-2)+":"+("0"+time.getMinutes()).slice(-2)+":"+("0"+time.getSeconds()).slice(-2)