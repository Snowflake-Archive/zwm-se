local wm = require(".lib.wm")

term.setCursorPos(2, 2)
term.write("Enter a path to a program to launch: ")
term.setCursorPos(2, 3)
local path = read()
wm.launch(path, {})