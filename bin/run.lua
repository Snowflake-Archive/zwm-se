local button = require(".lib.ui.button")
local input = require(".lib.ui.input")
local focusableEventManager = require(".lib.ui.focusableEventManager")
local events = require(".lib.events")

local w, h = term.getSize()

local manager = events:new()
local focusableManager = focusableEventManager:new()
local path = ""

local okay = button:new(w - 4, h - 1, "OK", function()
  _ENV.wm.addProcess(path, { isCentered = true }, true)
  _ENV.wm.killProcess(_ENV.wm.id)
end, true)

local cancel = button:new(w - 14, h - 1, "Cancel", function()
  _ENV.wm.killProcess(_ENV.wm.id)
end)

local path = input:new(2, 4, w - 4, function(content) 
  if #content == 0 then
    okay:setDisabled(true)
  else
    okay:setDisabled(false)
  end
  path = content
end, function(content, type)
  path = content
  if type == "return" then
    _ENV.wm.addProcess(content, { isCentered = true }, true)
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

focusableManager:addButton(okay)
focusableManager:addButton(cancel)
focusableManager:addInput(path)

focusableManager:inject(manager)
render()

events:listen()