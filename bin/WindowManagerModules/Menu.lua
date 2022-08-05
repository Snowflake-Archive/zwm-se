local util = require(".lib.util")

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

  return o
end

function menu:render(processes)
  local oldX, oldY = term.getCursorPos()
  local oldColor = term.getTextColor()
  term.redirect(self.buffer)

  local w, h = term.getSize()
  term.setCursorPos(2, h)
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.gray)
  term.clearLine()
  term.write("+")

  local time = os.time("ingame")
  local timeString = textutils.formatTime(time, true)
  term.setCursorPos(w - #timeString, h)
  term.write(timeString)

  term.setCursorPos(4, h)
  self.processPositions = {}

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

  term.setTextColor(oldColor)
  term.setCursorPos(oldX, oldY)
end

function menu:fire(e)
  if e[1] == "mouse_click" then
    local x, y = e[3], e[4]
    if y == self.h then
      for i, v in pairs(self.processPositions) do
        if x >= v.min and x <= v.max then
          os.queueEvent("focusProcess", v.id)
        end
      end
    end
  end
end

return menu