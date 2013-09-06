Buffer = (maxSize) ->
	bufferArr = []
	this.get = () -> bufferArr
	this.at = (i) -> bufferArr[i]

	this.push = (data) -> 
		bufferArr.shift() if bufferArr.length >= maxSize
		bufferArr.push data

	this.pop = () -> bufferArr.pop()
	return

module.exports = Buffer