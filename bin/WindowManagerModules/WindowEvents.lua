local events = {}

local function redirect(process, e)
  if e[1] ~= "timer" then
    local se = ""

    for i, v in pairs(e) do
      se = se .. " " .. tostring(v)
    end
  end

  coroutine.resume(process.coroutine, unpack(e))
end

function events:redirectEventsForMouse(p, e, idx, diso)
  if p.hideFrame then
    redirect(p, {e[1], e[2], e[3] - p.x, e[4] - p.y}) 
  else
    if e[4] == p.y then
      if e[1] == "mouse_click" then
        if e[3] >= p.x + p.w - 3 and e[3] <= p.x + p.w - 1 then
          os.queueEvent("killProcess", idx)
        elseif e[3] >= p.x + p.w - 6 and e[3] <= p.x + p.w - 4 then
          if p.hideMaximize == true and p.hideMinimize == true then
            return
          elseif p.hideMaximize == true then
            p.minimized = true
            p.focused = false
          else
            p.maxamized = not p.maxamized

            if p.maxamized then
              p.w_orig = p.w
              p.h_orig = p.h
              p.x_orig = p.x
              p.y_orig = p.y

              p.w = w
              p.h = h - 1
              p.x = 1
              p.y = 1
              p.window.reposition(p.x, p.y + 1, p.w, p.h - 1)
            else
              p.w = p.w_orig
              p.h = p.h_orig
              p.x = p.x_orig
              p.y = p.y_orig
              p.window.reposition(p.x, p.y + 1, p.w, p.h - 1)
            end
          end
        elseif e[3] >= p.x + p.w - 9 and e[3] <= p.x + p.w - 5 then
          if p.hideMinimize == true or p.hideMaxamize then
            return
          else
            p.minimized = true
            p.focused = false
          end
        elseif p.maxamized == false then
          self.windowDraggingState = {
            x = e[3],
            y = e[4],
            idx = idx,
          }
        end
      end
    else
      redirect(p, {e[1], e[2], e[3] - p.x + 1, e[4] - p.y}) 
    end
  end
end

function events:windowDrag(e, processes)
  if self.windowDraggingState then
    local p = processes[self.windowDraggingState.idx]

    local newX = e[3]
    local newY = e[4]
    local deltaX = newX - self.windowDraggingState.x
    local deltaY = newY - self.windowDraggingState.y
    p.x = p.x + deltaX
    p.y = p.y + deltaY

    if p.hideFrame == true then
      p.window.reposition(p.x, p.y)
    else
      p.window.reposition(p.x, p.y + 1)
    end

    self.windowDraggingState.x = newX
    self.windowDraggingState.y = newY
  end

  if self.windowResizeState and e[2] == 1 then
    local p = processes[self.windowResizeState.idx]
    local newX = e[3]
    local newY = e[4]
    local deltaX = newX - self.windowResizeState.x
    local deltaY = newY - self.windowResizeState.y

    if p.w + deltaX <= 0 or p.h + deltaY <= 1 then
      self.windowResizeState = nil
      return
    end
    p.w = p.w + deltaX
    p.h = p.h + deltaY

    if p.hideFrame == true then
      p.window.reposition(p.x, p.y, p.w, p.h)
    else
      p.window.reposition(p.x, p.y + 1, p.w, p.h - 1)
    end

    local old = term.current()
    term.redirect(p.window)
    coroutine.resume(p.coroutine, "term_resize")
    term.redirect(old)
  end
end

--- Creates a window renderr manager.
-- @return WindowRenderer The window renderer
function events:new(logger, buffer)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  self.buffer = buffer
  self.logger = logger
  self.windowDraggingState = nil
  self.windowResizingState = nil

  return o
end

function events:fire(e, processes, displayOrder)
  w, h = self.buffer.getSize()
  local didHitMouse = false
  local gotFocusTarget = false

  -- Display order prep
  local onCompleteDisplayOrder = {}

  for i, v in pairs(displayOrder) do
    onCompleteDisplayOrder[i] = v
  end

  -- Event Logging
  if e[1] ~= "timer" then
    local se = ""

    for i, v in pairs(e) do
      se = se .. " " .. tostring(v)
    end

    self.logger:debug("Event: %s", se)
  end

  -- Window dragging
  if e[1] == "mouse_up" then
    self.windowDraggingState = nil
    self.windowResizeState = nil
  elseif e[1] == "mouse_drag" then
    if self.windowDraggingState or self.windowResizeState then
      self:windowDrag(e, processes, displayOrder)
    end
  end

  -- Checking events
  for i = 1, #displayOrder, 1 do
    local newOrder = i
    local o = displayOrder[i] -- display order index
    local v = processes[o] -- process

    if v and v.isService == false then
      if e[1] ~= "timer" then
        self.logger:debug("Process %d: %s", o, v.title)
      end

      term.redirect(v.window)

      if e[1] == "term_resize" then
        coroutine.resume(v.coroutine)
      -- Focused redirection
      elseif v.focused == true then
        if e[1]:match("^mouse_%a+") then
          if e[3] >= v.x and e[3] <= v.x + v.w - 1 and e[4] >= v.y and e[4] <= v.y + v.h - 1 then
            self:redirectEventsForMouse(v, e, o, i)
            didHitMouse = true
          elseif e[2] == 1 and e[3] == v.x + v.w and e[4] == v.y + v.h and v.isResizeable == true and
            v.maxamized == false then
            didHitMouse = true
            self.windowResizeState = {
                x = e[3],
                y = e[4],
                idx = o
            }
          end
          -- Did not match mouse
        else
          redirect(v, e)
        end
        -- Focused == false
      else
        -- Unfocused redirection and checking
        local canRedirect = true

        if e[1] == "mouse_click" or e[1] == "mouse_drag" or e[1] == "mouse_scroll" or e[1] == "mouse_up" or e[1] ==
          "paste" or e[1] == "key" or e[1] == "key_up" or e[1] == "char" then
          canRedirect = false
        end

        if v.minimized == false and e[1] == "mouse_click" and gotFocusTarget == false and didHitMouse == false then
          if e[3] >= v.x and e[3] <= v.x + v.w - 1 and e[4] >= v.y and e[4] <= v.y + v.h - 1 then
            for i, v in pairs(processes) do
              v.focused = false
            end
            v.focused = true
            term.redirect(self.buffer)
            self:redirectEventsForMouse(v, e, o, i)
            term.redirect(v.window)
            didHitMouse = true
            gotFocusTarget = true

            table.remove(onCompleteDisplayOrder, i)
            table.insert(onCompleteDisplayOrder, 1, "")
            onCompleteDisplayOrder[1] = o
          else
            coroutine.resume(v.coroutine)
          end
        else
          if canRedirect then
            redirect(v, e)
          else
            coroutine.resume(v.coroutine)
          end
        end
      end
    end
  end

  term.redirect(self.buffer)

  if didHitMouse == false and e[1]:match("^mouse_%a+") and e[4] ~= h then
    for i, v in pairs(processes) do
      if v.focused == true then
        v.focused = false
        break
      end
    end
  end

  return onCompleteDisplayOrder
end

return events