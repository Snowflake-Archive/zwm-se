local drawUtils = require('.lib.utils.draw')
local buttonManager = require(".lib.ui.button")
local reader = require(".lib.registry.Reader"):new("user")
local events = require('.lib.events'):new()
local uiManager = require('.lib.ui.uiManager'):new()

local focused = true

local shutdown = buttonManager:new{
  x = 3, 
  y = 4, 
  text = "Shutdown", 
  callback = os.shutdown,
  colors = {
    background = reader:get("Appearance.ShutdownMenu.ShutdownButton"),
    text = reader:get("Appearance.ShutdownMenu.ShutdownButtonText"),
    clicking = reader:get("Appearance.ShutdownMenu.ShutdownButtonText"),
  },
}

local reboot = buttonManager:new{
  x = 15, 
  y = 4, 
  text = "Reboot", 
  callback = os.reboot,
  colors = {
    background = reader:get("Appearance.ShutdownMenu.RebootButton"),
    text = reader:get("Appearance.ShutdownMenu.RebootButtonText"),
    clicking = reader:get("Appearance.ShutdownMenu.RebootButtonText"),
  },
}

local cancel = buttonManager:new{
  x = 9, 
  y = 7, 
  text = "Cancel", 
  callback = function()
    _ENV.wm.killProcess(_ENV.wm.id)
  end,
}

uiManager:addButton(shutdown)
uiManager:addButton(reboot)
uiManager:addButton(cancel)
uiManager:inject(events)

local function render()
  local w, h = term.getSize()
  term.setBackgroundColor(reader:get("Appearance.Application.ApplicationBackground"))
  term.clear()
  drawUtils.drawBorder(1, 1, w, h, focused and reader:get("Appearance.Window.WindowFocused") or reader:get("Appearance.Window.WindowUnfocused"), "1-box-outside")

  term.setCursorPos(1, 2)
  term.setTextColor(reader:get("Appearance.Application.ApplicationTextStrong"))
  drawUtils.writeCentered("Power Options", nil, 1)

  shutdown:render()
  reboot:render()
  cancel:render()
end

events:addListener("term_resize", render)

events:addListener("wm_focus_gained", function()
  focused = true
  render()
end)

events:addListener("wm_focus_lost", function()
  focused = false
  render()
end)

render()

events:listen()