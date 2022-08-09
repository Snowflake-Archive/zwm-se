local util = require(".lib.util")
local input = require(".lib.ui.input")
local eventManager = require(".lib.events")
local focusableEventManager = require(".lib.ui.focusableEventManager")

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

  self.eventManager = eventManager:new()
  self.focusableEventManager = focusableEventManager:new()

  self.searchInput = input:new(1, 1, 10, function(data)
    self.searchContent = data
  end, function() end, "Search...", nil, nil, false)

  self.focusableEventManager:addInput(self.searchInput)

  self.focusableEventManager:inject(eventManager)

  return o
end

function menu:render(processes)
  local oldX, oldY = term.getCursorPos()
  local oldColor = term.getTextColor()
  term.redirect(self.buffer)
  local w, h = term.getSize()
  term.setCursorPos(1, h)

  self.searchInput:reposition(2, h - 2)

  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.gray)
  term.clearLine()
  
  term.setTextColor(self.isMenuVisible and colors.lightGray or colors.white)
  term.setBackgroundColor(self.isMenuVisible and colors.black or colors.gray)
  
  term.write(" + ")

  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.gray)

  local time = os.time("ingame")
  local timeString = textutils.formatTime(time, true)
  term.setCursorPos(w - #timeString, h)
  term.write(timeString)

  term.setCursorPos(4, h)
  self.processPositions = {}

  self.w = w
  self.h = h

  for i, v in pairs(processes) do
    if v.isService ~= true then
      local x = term.getCursorPos()
      if v.focused then
        term.setBackgroundColor(colors.black)
      else
        term.setBackgroundColor(colors.gray)
      end
      term.write((" %s "):format(v.title or fs.getName(v.startedFrom)))
      local xE = term.getCursorPos()

      table.insert(self.processPositions, {
        min = x,
        max = xE - 1,
        id = i
      })
    end
  end

  util.drawPixelCharacter(w, h, false, true, false, true, false, true, colors.black, colors.gray)
  self.searchInput:setVisible(self.isMenuVisible)

  if self.isMenuVisible then
    paintutils.drawFilledBox(1, h - 14, 16, h - 1, colors.gray)
    self.searchInput:render()
  end

  term.setTextColor(oldColor)
  term.setCursorPos(oldX, oldY)
end

function menu:fire(e)
  self.eventManager:check(e)

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
end

return menu