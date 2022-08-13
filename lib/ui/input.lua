--- Inputs with many features. Includes an event manager for the inputs aswell.
-- @module[kind=ui] Input

local drawing = require(".lib.utils.draw")
local strings = require("cc.strings")
local reigstryReader = require(".lib.registry.Reader")
local expect = require("cc.expect").expect

local reader = reigstryReader:new("user")
local input = {}

--- Creates a new input object.
-- @tparam number x The X position of the input.
-- @tparam number y The Y position of the input.
-- @tparam number w The width of the input.
-- @tparam function onChange Fires when the content of the input changes.
-- @tparam function onComplete Fires when the input is defocused. This will fire with a method to defocusization, either "return" or "defocus"
-- @tparam[opt] string placeholder Text that will be rendered if the input is empty.
-- @tparam[opt] boolean disabled Whether or not the input can be focused
-- @tparam[opt] string default The default content of the input
-- @tparam[opt] boolean visible Whether or not the input is visible. Default is true, if this is false the input won't render, nor will it be visible. 
-- @return Input The net input.
function input:new(x, y, w, onChange, onComplete, placeholder, disabled, default, visible)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, w, "number")
  expect(4, onChange, "function")
  expect(5, onComplete, "function")
  expect(6, placeholder, "string", "nil")
  expect(7, disabled, "boolean", "nil")
  expect(8, default, "string", "nil")
  expect(9, visible, "boolean", "nil")

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
    visible = visible or true,
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

--- Repositions an input.
-- @tparam number x The X position to move the input to.
-- @tparam number y The Y position to move the input to.
function input:reposition(x, y)
  expect(1, x, "number")
  expect(2, y, "number")

  self.x = x 
  self.y = y
end

--- Sets the content of the input.
-- @tparam string content The new content of the input.
function input:setContent(content)
  expect(1, content, "string")

  self.cursor = 0
  self.displayStartAt = 0
  
  self.content = content
  self:render(true)
end

--- Sets whether or not the input is disabled. If this is true, the input will be greyed out and not selectable.
-- @tparam boolean disabled Whether the input is disabled or not.
function input:setDisabled(disabled)
  expect(1, disabled, "boolean")

  self.disabled = disabled == true
  self:render(true)
end

--- Sets whether or not the input is visible. Note that the whole screen will need to be re-rendered to make the input disappear.
-- @tparam boolean visible Whether or not the input is disabled.
function input:setVisible(visible)
  expect(1, visible, "boolean")

  self.visible = visible == true
  self:render(true)
end

--- Sets whether or not the input is focused.
-- @tparam boolean focused Whether or not the input is focused.
function input:setFocused(focused)
  expect(1, focused, "boolean")

  self.isFocused = focused
  self:render(true)
end

--- Sets the placeholder for the input.
-- @tparam boolean focused Whether or not the input is focused.
function input:setPlaceholder(placeholder)
  expect(1, placeholder, "string")

  self.placeholder = placeholder
  self:render(true)
end

--- Resizes the input.
-- @tparam number w The new width of the input.
function input:resize(w)
  expect(1, w, "number")

  self.w = w
  self:render(true)
end

--- Renders an input.
function input:render()
  if self.visible then
    self.bgOnRender = term.getBackgroundColor()
    drawing.drawBorder(self.x - 1, self.y - 1, self.w + 4, 3, 
      self.isFocused and 
      reader:get("Appearance.UserInterface.Input.Focused") or 
      reader:get("Appearance.UserInterface.Input.Border"), 
      "1-box")
    term.setTextColor(reader:get("Appearance.UserInterface.Input.Text"))
    term.setBackgroundColor(reader:get("Appearance.UserInterface.Input.Background"))
    term.setCursorPos(self.x, self.y)
    term.write((" "):rep(self.w + 2))
    term.setCursorPos(self.x, self.y)

    if #self.content == 0 then
      term.setTextColor(reader:get("Appearance.UserInterface.Input.PlaceholderText"))
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
      term.setTextColor(reader:get("Appearance.UserInterface.Input.Text"))
      term.setCursorBlink(true)
    else
      term.setCursorBlink(false)
    end

    term.setBackgroundColor(self.bgOnRender)
  end
end

--- Fires events (key & char) to an input
-- @tparam table e The event table
function input:fire(e)
  expect(1, e, "table")

  if e[1] == "char" then
    local c = e[2]
    self.content = self.content:sub(1, self.cursor) .. c .. self.content:sub(self.cursor + 1)

    self.cursor = self.cursor + 1

    if #self.content >= self.w + 2 and (self.cursor == #self.content or self.cursor - self.displayStartAt >= self.w + 2) then
      self.displayStartAt = self.displayStartAt + 1
    end

    self.onChange(self.content)
    self:render()
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
      self.onChange(self.content)
      self:render()
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

return input