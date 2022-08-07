local util = require(".lib.util")
local strings = require("cc.strings")

local input = {
  eventManager = {}
}

--- Creates a new input object.
-- @tparam number x The X position of the input.
-- @tparam number y The Y position of the input.
-- @tparam function onChange Fires when the content of the input changes.
-- @tparam function onComplete Fires when the input is defocused. This will fire with a method to defocusization, either "return" or "defocus"
-- @tparam[opt] string placeholder Text that will be rendered if the input is empty.
-- @tparam[opt] boolean disabled Whether or not the input can be focused
-- @tparam[opt] string default The default content of the input
-- @tparam[opt] boolean enabled Whether or not the input is enabled. Default is true, if this is false the input won't render, nor will it be visible. 
function input:new(x, y, w, onChange, onComplete, placeholder, disabled, default, enabled)
  local o = {
    x = x,
    y = y,
    w = w,
    content = default or "",
    onChange = onChange,
    onComplete = onComplete,
    placeholder = placeholder or "",
    cursor = default and #default or 0,
    displayStartAt = 0,
    disabled = disabled == true,
    isFocused = false,
    enabled = enabled or true,
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

function input:focus()
  self.isFocused = true
end

function input:unfocus()
  self.isFocused = false
end

function input:render()
  if self.enabled then
    self.bgOnRender = term.getBackgroundColor()
    util.drawBorder(self.x - 1, self.y - 1, self.w + 4, 3, self.isFocused and colors.lightBlue or colors.lightGray, "1-box")
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.white)
    term.setCursorPos(self.x, self.y)
    term.write((" "):rep(self.w + 2))
    term.setCursorPos(self.x, self.y)

    if #self.content == 0 then
      term.setTextColor(colors.lightGray)
      term.write(strings.ensure_width(self.placeholder, self.w))
    else
      term.write(self.content:sub(self.displayStartAt + 1, self.displayStartAt + self.w + 1))
    end

    if self.isFocused == true then
      if #self.content == 0 then
        term.setCursorPos(self.x, self.y)
      else
        term.setCursorPos(self.x + (self.cursor - self.displayStartAt), self.y)
      end
      term.setTextColor(colors.black)
      term.setCursorBlink(true)
    else
      term.setCursorBlink(false)
    end

    term.setBackgroundColor(self.bgOnRender)
  end
end

function input:fire(e)
  if e[1] == "char" then
    local c = e[2]
    self.content = self.content:sub(1, self.cursor) .. c .. self.content:sub(self.cursor + 1)

    self.cursor = self.cursor + 1

    if #self.content >= self.w + 2 and (self.cursor == #self.content or self.cursor - self.displayStartAt >= self.w + 2) then
      self.displayStartAt = self.displayStartAt + 1
    end

    self:render()
    self.onChange(self.content)
  elseif e[1] == "key" then
    local k = e[2]

    -- TODO: add end, home, delete, and selection support

    if k == keys.backspace then
      if self.cursor > 0 then
        self.content = self.content:sub(1, self.cursor - 1) .. self.content:sub(self.cursor + 1)
        self.cursor = math.max(0, self.cursor - 1)

        if #self.content >= self.w + 1 then
          self.displayStartAt = self.displayStartAt - 1
        end
      end
      self:render()
      self.onChange(self.content)
    elseif k == keys.enter then
      self.onComplete(self.content, "return")
      self.isFocused = false
      self:render()
    elseif k == keys.right then
      if self.cursor - self.displayStartAt >= self.w + 1 then
        self.displayStartAt = math.min(#self.content - self.w - 1, self.displayStartAt + 1)
      end
      self.cursor = math.min(#self.content, self.cursor + 1)
      self:render()
    elseif k == keys.left then
      if self.cursor - self.displayStartAt <= 0 then
        self.displayStartAt = math.max(0, self.displayStartAt - 1)
      end
      self.cursor = math.max(0, self.cursor - 1)
      self:render()
    end
  end
end

function input.eventManager:new()
  local o = {
    objects = {}
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

function input.eventManager:add(input)
  table.insert(self.objects, input)
end

function input.eventManager:inject(manager)
  manager:addListener("key", function(k)
    for i, v in pairs(self.objects) do
      if v.isFocused then
        v:fire({"key", k})
      end
    end
  end)

  manager:addListener("char", function(c)
    for i, v in pairs(self.objects) do
      if v.isFocused then
        v:fire({"char", c})
      end
    end
  end)

  manager:addListener("mouse_click", function(m, x, y)
    if m == 1 then
      for i, v in pairs(self.objects) do
        if x >= v.x and x <= v.x + v.w - 1 and v.y == y then
          v:focus()
          v:render()
        elseif v.isFocused == true then
          v.onComplete(v.content, "defocus")
          v:unfocus()    
          v:render()
        end
      end
    end
  end)
end

return input