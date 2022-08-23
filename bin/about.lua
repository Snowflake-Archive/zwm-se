if not _ENV.wm then error("Missing wm environment") end

_ENV.wm.setProcessTitle(_ENV.wm.id, "About zWM SE")

local button = require(".lib.ui.button")
local scrollbox = require(".lib.ui.scrollbox"):new{
  x = 2, 
  y = 2, 
  w = 1, 
  h = 1, 
  parent = term.current(), 
  renderScrollbars = {y = true},
}

local focusManager = require(".lib.ui.uiManager"):new()
local eventManager = require(".lib.events"):new()
local RegistryReader = require(".lib.registry.Reader")
local strings = require("cc.strings")

local version = _HOST:match("[%d%.]+")
local host = _HOST:match("%((.-)%)")
local lua = _VERSION

local machineReader = RegistryReader:new("machine")

local ok = button:new{
  x = 1, 
  y = 1, 
  text = "OK", 
  callback = function()
    _ENV.wm.killProcess(_ENV.wm.id)
  end,
}

local learnMore = {
  minX = 0,
  maxX = 0,
  y = 0,
}

focusManager:addButton(ok)
focusManager:inject(eventManager)
scrollbox:addToEventManager(eventManager)

local function drawRow(title, value, y, w)
  term.setCursorPos(1, y)
  term.setTextColor(colors.black)
  term.write(title)
  term.setCursorPos(w - #value, y)
  term.setTextColor(colors.gray)
  term.write(value)
end

local function render()
  term.setBackgroundColor(colors.white)
  term.clear()
  local w, h = term.getSize()

  local licenseDisclaimer = "zWM SE is liscensed under GNU General Public License v2.0."

  scrollbox:reposition(2, 2, w - 2, h - 4)
  ok:reposition(w - 5, h - 1)

  local title = "zWM Section Edition"

  local o = term.current()
  term.redirect(scrollbox:getTerminal())
  term.setBackgroundColor(colors.white)
  term.clear()
  term.setTextColor(colors.black)
  term.setCursorPos(w / 2 - math.floor(#title / 2 + 0.5), 1)
  term.write(title)
  drawRow("Version", ("%s (%d)"):format(machineReader:get("SystemVersionName"), machineReader:get("SystemVersionNumber")), 3, w - 3)
  drawRow("Version Date", ("%s"):format(machineReader:get("SystemVersionDate")), 4, w - 3)
  drawRow("CC Version", version or "???", 5, w - 3)
  drawRow("CC Host", host or "???", 6, w - 3)
  drawRow("Lua Version", lua or "???", 7, w - 3)
  drawRow("Lead Developer", "znepb", 9, w - 3)

  local lines = strings.wrap(licenseDisclaimer, w - 3)
  for i, l in pairs(lines) do
    term.setCursorPos(1, 10 + i)
    term.write(l)
  end

  term.setCursorPos(1, 10 + #lines + 1)
  learnMore.y = 10 + #lines + 1
  term.setTextColor(colors.blue)
  term.write("Learn More")
  learnMore.maxX = term.getCursorPos()

  term.redirect(o)

  term.setTextColor(colors.gray)

  ok:render()

  scrollbox:redraw()
end

render()

eventManager:addListener("term_resize", function()
  render()
end)

local _, err = pcall(function()
  eventManager:listen()
end)

term.redirect(term.native())
term.setCursorPos(1, 1)
print(err)
