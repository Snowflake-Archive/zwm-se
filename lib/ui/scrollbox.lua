--- A fancy scrollbox creater that have scrollbars and scrolling boxes.
-- @moudle[kind=ui] Scrollbox
-- @author Marcus Wenzel

local scrollbox = {}

--- Creates a scrollbox frame.
-- @tparam number x The X position of the scrollbox frame.
-- @tparam number y The Y position of the scrollbox frame.
-- @tparam number w The width of the scrollbox frame.
-- @tparam number h The height of the scrollbox frame.
-- @tparam table parent The parent term of the scrollbox window.
-- @tparam[opt] table renderScrollbars A table containing an X and Y paramater, if either is true, a scrollbar will be rendered for that axis.
-- @return Scrollbox The created scrollbox instance.
function scrollbox:new(x, y, w, h, parent, renderScrollbars)
  local newW, newH = w, h

  if renderScrollbars then
    if renderScrollbars.x then
      newH = h - 1
    end
    if renderScrollbars.y then
      newW = w - 1
    end
  end

  local scrollWin = window.create(parent, x, y, newW, newH)

  local o = {
    x = x,
    y = y,
    w = w,
    h = h,
    scrollWin = scrollWin,
    scrollX = 1,
    scrollY = 1,
    maxWidth = 0,
    maxHeight = 0,
    doRenderScrollbars = renderScrollbars,
    parent = parent,
    items = {}
  }

  local function renderScrollbars()
    if o.doRenderScrollbars.y and o.maxHeight > o.h then
      parent.setCursorPos(o.x + o.w - 1, o.y)
      parent.write("\30")
      parent.setCursorPos(o.x + o.w - 1, o.y + o.h - 1)
      parent.write("\31")
  
      for i = o.y + 1, o.y + o.h - 2 do
        parent.setCursorPos(o.x + o.w - 1, i)
        parent.write("|")
      end
      
      local lineMin = o.y + 1
      local lineMax = o.y + o.h - 2
      local progress = (-o.scrollY + 2) / o.maxHeight
      local lineHeight = lineMax - lineMin
      local line = lineMin + math.floor(progress * lineHeight)

      parent.setCursorPos(o.x + o.w - 1, line)
      parent.write("\127")
    end
  end

  local function redraw()
    local oldX, oldY = scrollWin.getCursorPos()
    local sX, sY = o.scrollX, o.scrollY
    scrollWin.clear()
    for i, v in pairs(o.items) do
      scrollWin.setCursorPos(v.x + sX - 1, v.y + sY - 1)
      scrollWin.blit(v.text, v.foreground, v.background)
    end
    scrollWin.setCursorPos(oldX, oldY)
    renderScrollbars()
  end 

  local function blit(text, foreground, background)
    local cx, cy = scrollWin.getCursorPos()
    o.maxWidth = math.max(o.maxWidth, cx + #text)
    o.maxHeight = math.max(o.maxHeight, cy)
    o.items[#o.items + 1] = {text = text, x = cx, y = cy, foreground = foreground, background = background}
    redraw()
  end
  
  local sbterm = {
    nativePaletteColour = scrollWin.nativePaletteColor,
    nativePaletteColor = scrollWin.nativePaletteColor,
    write = function(text)
      blit(text, colors.toBlit(scrollWin.getTextColor()):rep(#text), colors.toBlit(scrollWin.getBackgroundColor()):rep(#text))
    end,
    scroll = function(y, x)
      scrollWin.clear()
      o.scrollX = o.scrollX + (x or 0)
      o.scrollY = o.scrollY + (-y or 0)
      redraw()
    end,
    getCursorPos = scrollWin.getCursorPos,
    setCursorPos = scrollWin.setCursorPos,
    getCursorBlink = scrollWin.getCursorBlink,
    setCursorBlink = scrollWin.setCursorBlink,
    getSize = function()
      return o.maxWidth, o.maxHeight
    end,
    clear = function()
      o.scrollWin.clear()
      o.maxWidth = 0
      o.maxHeight = 0
      o.items = {}
    end,
    clearLine = scrollWin.clearLine,
    getTextColour = scrollWin.getTextColor,
    getTextColor = scrollWin.getTextColor,
    setTextColour = scrollWin.setTextColor,
    setTextColor = scrollWin.setTextColor,
    getBackgroundColour = scrollWin.getBackgroundColor,
    getBackgroundColor = scrollWin.getBackgroundColor,
    setBackgroundColour = scrollWin.setBackgroundColor,
    setBackgroundColor = scrollWin.setBackgroundColor,
    isColour = scrollWin.isColor,
    isColor = scrollWin.isColor,
    blit = blit,
    setPaletteColor = scrollWin.setPaletteColor,
    setPaletteColour = scrollWin.setPaletteColor,
    redirect = scrollWin.redirect,
    current = scrollWin.current,
    native = scrollWin.native,
    setVisible = function(value)
      scrollWin.setVisible(value)
    end,
    redraw = redraw
  }

  setmetatable(o, self)
  self.sbterm = sbterm
  self.__index = self
  return o
end

--- Redraws a scrollbox.
function scrollbox:redraw()
  self.sbterm.redraw()
end

--- Gets the scrollbox's terminal.
function scrollbox:getTerminal()
  return self.sbterm
end

--- Gets the scroll position of a scrollbox.
-- @returns The X and Y scroll position.
function scrollbox:getScroll()
  return self.scrollX, self.scrollY
end

function scrollbox:reposition(x, y, w, h)
  local winW = self.w
  if x then self.x = x end
  if y then self.y = y end
  if w then 
    self.w = w
    if self.doRenderScrollbars and self.doRenderScrollbars.y then
      winW = self.w - 1
    end
  end
  if h then self.h = h end

  self.scrollWin.reposition(self.x, self.y, winW, self.h)
end

--- Scrolls the specified delta, and ensures it can be scrolled to.
-- @tparam number d The delta to scroll.
function scrollbox:ensureScroll(d)
  local sX, sY = self:getScroll()
  local ssX, ssY = self.sbterm.getSize()

  local canscroll = false
  if d == 1 then -- down
    canscroll = (-sY + 2) < ssY
  elseif d == -1 then -- up
    canscroll = sY <= 0
  end

  if canscroll == true then self.sbterm.scroll(d) end
end

--- Fires a scroll event.
-- @tparam number d The delta to scroll.
-- @tparam number x The X position of the scroll.
-- @tparam number y The Y position of the scroll.
function scrollbox:onMouseScroll(d, x, y)
  if x >= self.x and x <= self.x + self.w - 1 and y >= self.y and y <= self.y + self.h - 1 then
    self:ensureScroll(d)
  end
end

--- Adds events to the specified EventManager.
-- @tparam EventManager em The EventManager to add events to.
function scrollbox:addToEventManager(eventManager)
  local function onBarScroll(y)
    local newY = y - self.y - 1
    local min = self.y + 1
    local max = self.y + self.h - 2
    local progress = newY / (max - min)
    local scroll = progress * self.maxHeight
    self.scrollY = -math.max(math.min(math.floor(scroll - 1), self.maxHeight - 2), -1)
    self:redraw()
  end

  eventManager:addListener("mouse_scroll", function(...)
    self:onMouseScroll(...)
  end)

  eventManager:addListener("mouse_click", function(m, x, y)
    if self.doRenderScrollbars.y then
      if m == 1 and x == self.x + self.w - 1 and y == self.y then
        self:ensureScroll(-1)
      elseif m == 1 and x == self.x + self.w - 1 and y == self.y + self.h - 1 then
        self:ensureScroll(1)
      elseif m == 1 and x == self.x + self.w - 1 and y >= self.y + 1 and y <= self.y + self.h - 2 then
        onBarScroll(y)
      end
    end
  end)

  eventManager:addListener("mouse_drag", function(m, x, y)
    if self.doRenderScrollbars.y then
      if m == 1 and x == self.x + self.w - 1 and y >= self.y + 1 and y <= self.y + self.h - 2 then
        onBarScroll(y)
      end
    end
  end)
end

return scrollbox