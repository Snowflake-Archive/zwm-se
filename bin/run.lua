local wm = require(".lib.wm")
local button = require(".lib.ui.button")
local input = require(".lib.ui.input")
local events = require(".lib.events")

local w, h = term.getSize()

local manager = events:new()
local buttonEventManager = button.eventManager:new()
local inputEventManager = input.eventManager:new()
local path = ""

local okay = button:new(w - 4, h - 1, "OK", function()
  _ENV.wm.addProcess(path, {}, true)
  _ENV.wm.killProcess(_ENV.wm.id)
end)

local cancel = button:new(w - 14, h - 1, "Cancel", function()
  _ENV.wm.killProcess(_ENV.wm.id)
end)

local path = input:new(2, 4, w - 4, function(content) 
  path = content
end, function(content, type)
  path = content
  if type == "return" then
    _ENV.wm.addProcess(content, {}, true)
    _ENV.wm.killProcess(_ENV.wm.id)
  end
end)
path:focus()

local function render()
  local w, h = term.getSize()
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.clear()

  term.setCursorPos(2, 2)
  term.write("Enter a path to run")

  path:render()
  okay:render()
  cancel:render()
end

buttonEventManager:add(okay)
buttonEventManager:add(cancel)
inputEventManager:add(path)

buttonEventManager:inject(manager)
inputEventManager:inject(manager)
render()

events:listen()