local util = require(".lib.utils")
local input = require(".lib.ui.input")
local button = require(".lib.ui.button")
local eventManager = require(".lib.events")
local scrollbox = require(".lib.ui.scrollbox")
local focusableEventManager = require(".lib.ui.focusableEventManager")
local RegistryReader = require(".lib.registry.Reader")

local menu = {}

--- Creates a window renderr manager.
-- @return WindowRenderer The window renderer
function menu:new(logger, buffer)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  self.buffer = buffer
  self.logger = logger
  self.processPositions = {}
  self.isMenuVisible = false
  self.searchContent = ""
  self.term = term.current()
  self.registry = RegistryReader:new("user")

  self.eventManager = eventManager:new()
  self.focusableEventManager = focusableEventManager:new()

  self.searchInput = input:new(1, 1, 9, function(data)
    self.searchContent = data
  end, function() end, "Search...", nil, nil, false)

  self.shutdownButton = button:new(1, 1, "O", function()
    os.reboot()
  end, nil, false, true, {
    background = self.registry:get("Appearance.Menu.ShutdownBackground"),
    clicking = self.registry:get("Appearance.Menu.ShutdownFocused"),
    text = self.registry:get("Appearance.Menu.ShutdownText"),
  })

  self.focusableEventManager:addInput(self.searchInput)
  self.focusableEventManager:addButton(self.shutdownButton)

  self.focusableEventManager:inject(eventManager)
  self.scroll = scrollbox:new(1, 1, 15, 10, buffer, {y = true})
  self:renderScrollbox()

  return o
end

function menu:renderScrollbox()
  local t = self.scroll:getTerminal()
  t.setBackgroundColor(colors.gray)
  t.setTextColor(colors.white)
  t.setCursorPos(1, 1)
  t.write("Pinned Apps")
end

function menu:render(processes)
  if processes then
    self.processes = processes
  end

  -- Prep
  local oldX, oldY = term.getCursorPos()
  local oldColor = term.getTextColor()
  term.redirect(self.buffer)
  local w, h = term.getSize()
  self.w = w
  self.h = h

  -- Render menubar
  term.setCursorPos(1, h)
  term.setTextColor(self.registry:get("Appearance.Menu.MenuText"))
  term.setBackgroundColor(self.registry:get("Appearance.Menu.MenuBackground"))
  term.clearLine()
  
  term.setTextColor(self.isMenuVisible and self.registry:get("Appearance.Menu.MenuFocusedText") or self.registry:get("Appearance.Menu.MenuText"))
  term.setBackgroundColor(self.isMenuVisible and self.registry:get("Appearance.Menu.MenuFocusedBackground") or self.registry:get("Appearance.Menu.MenuBackground"))
  
  term.write(" + ")

  --[[
  TODO: make this work properly

  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.gray)
  local time = os.time("ingame")
  local timeString = textutils.formatTime(time, true)
  term.setCursorPos(w - #timeString, h)
  term.write(timeString)
  ]]

  -- Render processes on menubar
  term.setCursorPos(4, h)
  self.processPositions = {}

  for i, v in pairs(self.processes) do
    if v.isService ~= true then
      local x = term.getCursorPos()
      term.setTextColor(v.focused and self.registry:get("Appearance.Menu.MenuFocusedText") or self.registry:get("Appearance.Menu.MenuText"))
      term.setBackgroundColor(v.focused and self.registry:get("Appearance.Menu.MenuFocusedBackground") or self.registry:get("Appearance.Menu.MenuBackground"))

      term.write((" %s "):format(v.title or fs.getName(v.startedFrom)))
      local xE = term.getCursorPos()

      table.insert(self.processPositions, {
        min = x,
        max = xE - 1,
        id = i,
      })
    end
  end

  if self.isMenuVisible then
    paintutils.drawFilledBox(1, h - 14, 16, h - 1, self.registry:get("Appearance.Menu.MenuBackground"))
    term.setTextColor(self.registry:get("Appearance.Menu.MenuText"))

    -- Make everything visible
    self.shutdownButton:setVisible(true)
    self.searchInput:setVisible(true)
  
    -- Move items to desired positions
    self.searchInput:reposition(2, h - 2)
    self.shutdownButton:reposition(15, h - 2)
    self.scroll:reposition(2, h - 13)
    self.scroll:redraw()
  else
    self.shutdownButton:setVisible(false)
    self.searchInput:setVisible(false)
  end

  term.setTextColor(oldColor)
  term.setCursorPos(oldX, oldY)
end

function menu:fire(e)
  self.eventManager:check(e)
  local oldIsMenuVisible = self.isMenuVisible

  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    if self.w and self.h and self.isMenuVisible and x >= 1 and x <= 16 and y >= self.h - 14 and y <= self.h - 1 then
      --"ok"
    elseif m == 1 then
      if y == self.h then
        for _, v in pairs(self.processPositions) do
          if x >= v.min and x <= v.max then
            os.queueEvent("focusProcess", v.id)
          end
        end

        if x >= 1 and x <= 3 then
          self.searchInput:setFocused(true)
          self.searchContent = ""
          self.searchInput:setContent("")
          self.isMenuVisible = not self.isMenuVisible
        else
          self.searchInput:setFocused(false)
          self.isMenuVisible = false
        end
      else
        self.searchInput:setFocused(false)
        self.isMenuVisible = false
      end
    else
      self.searchInput:setFocused(false)
      self.isMenuVisible = false
    end
  end

  if oldIsMenuVisible ~= self.isMenuVisible then
    self:render()
  end

  return oldIsMenuVisible ~= self.isMenuVisible
end

return menu