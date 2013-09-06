window.filterSingle = (array, func) -> return {id:i,elem:x} for x,i in array when func x

window.scrollBottom = () -> $("#centerbar").animate { scrollTop: $("#centerbar").height() }, "fast"