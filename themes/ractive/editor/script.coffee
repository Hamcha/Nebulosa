starterSettings =
	value: "var hello = function (nick,to,text) {\n\t// Your code here\n};\n\nbind(\"message\",hello);"
	mode: "javascript"
	theme: "monokai"
	lineNumbers: true
	lineWrapping: true
	indentWithTabs: true
	indentUnit: 4
	tabMode: "indent"
	showTrailingSpace: true
	extraKeys: 
		"Ctrl-Q": (cm) -> cm.foldCode cm.getCursor()
		"Ctrl-Space": "autocomplete"
	foldGutter: true
	gutters: ["CodeMirror-lint-markers"]
	lint: true
	highlightSelectionMatches: {showToken: /\w/}

codeEditor = wrapper = undefined
currentMode = starterSettings.mode

CodeMirror.commands.autocomplete = (cm) -> CodeMirror.showHint cm, CodeMirror.hint.javascript

$(document).ready () ->
	wrapper = document.getElementById "editor"
	codeEditor = CodeMirror wrapper, starterSettings