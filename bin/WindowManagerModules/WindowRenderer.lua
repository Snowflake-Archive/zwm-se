local util = require(".lib.util")
local registry = require(".lib.registry")

local renderer = {}

--- Creates a window renderr manager.
-- @return WindowRenderer The window renderer
function renderer:new(logger, buffer, displayOrder, processes)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  self.buffer = buffer
  self.displayOrder = displayOrder
  self.processes = processes
  self.logger = logger
  self.backgroundLayers = {}

  return o
end

--- Renders a single process.
-- @tparam Process process The process to render.
function renderer:renderProcess(p)
  local oTerm = term.current()
  term.redirect(self.buffer)
  local w, h = self.buffer.getSize()

  self.backgroundLayers = {}

  if p.isService ~= true and p.minimized == false then
    if not p.hideFrame then
      -- Topbar Rendering

      local color = p.focused and registry.readKey("machine", "Appearance.WindowFocused") or registry.readKey("machine", "Appearance.WindowUnfocused")

      paintutils.drawLine(p.x, p.y, p.x + p.w - 1, p.y, color)
      term.setTextColor(registry.readKey("machine", "Appearance.TitlebarText"))
      term.setCursorPos(p.x, p.y)
      term.write(p.title)

      term.setCursorPos(p.x + p.w - 3, p.y)
      term.setBackgroundColor(registry.readKey("machine", "Appearance.CloseButton"))
      term.setTextColor(registry.readKey("machine", "Appearance.CloseButtonText"))
      term.write(" x ")

      local nextButtonRenderAt = p.x + p.w - 6

      term.setBackgroundColor(registry.readKey("machine", "Appearance.ControlButton"))
      term.setTextColor(registry.readKey("machine", "Appearance.ControlButtonText"))

      if p.hideMaximize == false then
        term.setCursorPos(nextButtonRenderAt, p.y)
        term.write(" " .. (p.isMaxamized and "-" or "+") .. " ")
        nextButtonRenderAt = nextButtonRenderAt - 3
      end

      if p.hideMinimize == false then
        term.setCursorPos(nextButtonRenderAt, p.y)
        term.write(" \31 ")
        nextButtonRenderAt = nextButtonRenderAt - 3
      end

      -- Left Edge
      if p.x >= 2 then
        for i = 1, p.h do
          if p.y + i - 1 <= h then
            local _, _, lineB = self.buffer.getLine(p.y + i - 1)

            local use = util.fromBlit(util.selectXfromBlit(p.x - 1, lineB))

            if self.backgroundLayers[p.y + i - 1] and self.backgroundLayers[p.y + i - 1][p.x] then
              use = self.backgroundLayers[p.y + i - 1][p.x]
            else
              if self.backgroundLayers[p.y + i - 1] == nil then
                self.backgroundLayers[p.y + i - 1] = {}
              end

              self.backgroundLayers[p.y + i - 1][p.x] = use
            end
            
            util.drawPixelCharacter(p.x - 1, p.y + i - 1, false, true, false, true, false, true, color, use)
          end
        end

       
        if p.y + p.h <= h then
          local _, _, line2 = self.buffer.getLine(p.y + p.h)
          util.drawPixelCharacter(p.x - 1, p.y + p.h, false, true, false, false, false, false, color, util.fromBlit(util.selectXfromBlit(p.x - 1, line2)))
        end
      end

      -- Bottom Edge
      if p.y + p.h <= h then
        local _, _, line2 = self.buffer.getLine(p.y + p.h)
        for i = 1, p.w do
          if p.x + i - 1 <= w and p.x + i - 1 >= 1 then
            local bg = util.fromBlit(util.selectXfromBlit(p.x + i - 1, line2))
            util.drawPixelCharacter(p.x + i - 1, p.y + p.h, true, true, false, false, false, false, color, bg)
          end
        end

        
        if p.x + p.w <= w then
          util.drawPixelCharacter(p.x + p.w, p.y + p.h, true, false, false, false, false, false, color, util.fromBlit(util.selectXfromBlit(p.x + p.w, line2)))
        end
      end

      -- Right Edge
      if p.x + p.w <= w then
        for i = 1, p.h do
          if p.y + i - 1 <= h then
            local _, _, line3 = self.buffer.getLine(p.y + i - 1)
            local bg = util.fromBlit(util.selectXfromBlit(p.x + p.w, line3))
            util.drawPixelCharacter(p.x + p.w, p.y + i - 1, true, false, true, false, true, false, color, bg)

            if self.backgroundLayers[p.y + i - 1] == nil then
              self.backgroundLayers[p.y + i - 1] = {}
            end

            self.backgroundLayers[p.y + i - 1][p.x + p.w + 1] = color
          end
        end
      end
    end

    term.redirect(p.window)
    coroutine.resume(p.coroutine)
    p.window.redraw()
  end

  term.redirect(oTerm)
end

--- Renders all active processes.
function renderer:renderProcesses(processes, displayOrder)
  self.processes = processes
  self.displayOrder = displayOrder
  term.redirect(self.buffer)
  for i = #self.displayOrder, 1, -1 do
    local v = self.displayOrder[i] -- display order index
    local p = self.processes[v] -- process
    if p then
      self:renderProcess(p, v, i)
    end
  end
end

return renderer