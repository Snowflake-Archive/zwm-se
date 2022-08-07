local util = require(".lib.util")

local button = {
  eventManager = {}
}

function button:new(x, y, text, callback, width, height, disabled, enabled)
  local o = {
    x = x,
    y = y,
    text = text,
    callback = callback,
    width = width,
    height = height,
    disabled = disabled == true,
    isFocused = false,
    isBeingClicked = false,
    enabled = enabled or true,
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

function button:reposition(x, y)
  self.x = x 
  self.y = y
end

function button:setText(text)
  self.text = text
  self:render(true)
end

function button:setDisabled(disabled)
  self.disabled = disabled == true
  self:render(true)
end

function button:setEnabled(enabled)
  self.enabled = enabled == true
end

function button:render(useBgRender)
  if self.enabled == true then
    local oX, oY = term.getCursorPos()

    if useBgRender and self.bgOnRender then
      term.setBackgroundColor(self.bgOnRender)
    else
      self.bgOnRender = term.getBackgroundColor()
    end

    local color = colors.lightGray

    if self.isBeingClicked == true then
      color = colors.gray
    elseif self.isFocused == true then
      color = colors.lightBlue
    end

    util.drawBorder(self.x - 1, self.y - 1, self.text:len() + 4, 3, color, "1-box")

    term.setCursorPos(self.x, self.y)
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(self.disabled and colors.gray or colors.black)
    term.write((" %s "):format(self.text))

    self.renderedWidth = self.text:len() + 2

    term.setBackgroundColor(self.bgOnRender)
    term.setCursorPos(oX, oY)
  end
end

function button:focus()
  self.isFocused = true
  self:render(true)
end

function button:unfocus()
  self.isFocused = false
  self:render(true)
end

function button:click(isFirst)
  if isFirst == true then
    self.isBeingClicked = true
    self:render(true)
  else
    self.isBeingClicked = false
    self.callback()
    self:focus()
    self:render(true)
  end
end

function button.eventManager:new()
  local o = {
    buttons = {}
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

function button.eventManager:add(button)
  table.insert(self.buttons, button)
end

function button.eventManager:inject(manager)
  manager:addListener("mouse_click", function(m, x, y)
    if m == 1 then
      for i, v in pairs(self.buttons) do
        if v.enabled and v.renderedWidth and y == v.y and x >= v.x and x <= v.x + v.renderedWidth - 1 then        
          v:click(true)
        else
          v.isFocused = false
          v:render(true)
        end
      end
    end
  end)

  manager:addListener("mouse_up", function(m, x, y)
    if m == 1 then
      for i, v in pairs(self.buttons) do
        if v.enabled and v.y == y and x >= v.x and x <= v.x + #v.text + 1 and v.isBeingClicked == true then
          v:click()
        end
      end

      for i, v in pairs(self.buttons) do
        v.isBeingClicked = false
        v:render(true)
      end
    end
  end)
end

return button