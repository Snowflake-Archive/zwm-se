--- Really fancy buttons
-- @module[kind=ui] Button

local drawing = require(".lib.utils.draw")
local reigstryReader = require(".lib.registry.Reader")
local ccexpect = require("cc.expect")
local expect, field = ccexpect.expect, ccexpect.field

local button = {}

--- Creates a new button. via a dictionary. The buttons width will be #text + 4.
-- The below parameters are in no particular order.
-- @tparam number x The X position of the button
-- @tparam number y The Y position of the button
-- @tparam string text The text that will be rendered inside the button.
-- @tparam function callback The function that is ran when the button is clicked.
-- @tparam[opt] boolean disabled If this is true, the button will be grayed out and not be selectable.
-- @tparam[opt] boolean visible If this is false, the button will not be rendered, nor selectable.
-- @tparam[opt] boolean disablePadding If this is true, the text of the button will be its actual text, and not padded.
-- @tparam[opt] table colors A table for colors, background, clicking, focused, text, and textDisabled 
-- @tparam[opt] table term The terminal to render the button in
-- @return Button The new button.
function button:new(options)
  expect(1, options, "table")

  local o = {
    x = field(options, "x", "number"),
    y = field(options, "y", "number"),
    text = field(options, "text", "string"),
    callback = field(options, "callback", "function"),
    disabled = field(options, "disabled", "boolean", "nil") == true,
    isFocused = false,
    isBeingClicked = false,
    visible = field(options, "visible", "boolean", "nil") ~= false,
    disablePadding = field(options, "disablePadding", "boolean", "nil") == true,
    colors = field(options, "colors", "table", "nil") or {},
    reader = reigstryReader:new("user"),
    type = "button",
    term = options.term,
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

--- Repositions a button.
-- @tparam number x The X position to move the button to.
-- @tparam number y The Y position to move the button to.
function button:reposition(x, y)
  expect(1, x, "number")
  expect(2, y, "number")

  self.x = x 
  self.y = y
end

--- Sets the text of a button.
-- @tparam string text The new text of the button.
function button:setText(text)
  expect(1, text, "string")

  self.text = text
  self:render(true)
end

--- Sets whether or not the button is disabled. If this is true, the button will be greyed out and not selectable.
-- @tparam boolean disabled Whether the button is disabled or not.
function button:setDisabled(disabled)
  expect(1, disabled, "boolean")

  self.disabled = disabled == true
  self:render(true)
end

--- Sets whether or not the button is visible. Note that the whole screen will need to be re-rendered to make the button disappear.
-- @tparam boolean visible Whether or not the button is disabled.
function button:setVisible(visible)
  expect(1, visible, "boolean")

  self.visible = visible ~= false
  self:render(true)
end

--- Sets whether or not the button is focused.
-- @tparam boolean focused Whether or not the button is focused.
function button:setFocused(focused)
  expect(1, focused, "boolean")

  local oldValue = self.isFocused
  local newValue = focused == true

  if oldValue ~= newValue then
    self.isFocused = focused == true
    self:render(true)
  end
end

--- Sets the callback of the button
-- @tparam function The button callback
function button:setCallback(callback)
  expect(1, callback, "function")

  self.callback = callback
end

--- Renders the button.
-- @tparam[opt] boolean useBgRender If this is true, the button will be rendered with the same background color used to render it last time.
function button:render(useBgRender)
  expect(1, useBgRender, "boolean", "nil")

  if self.visible == true then
    local oT = term.current()

    if self.term then term.redirect(self.term) end

    local oX, oY = term.getCursorPos()

    local displayStr = self.text
    
    if self.disablePadding == false then
      displayStr = " " .. displayStr .. " "
    end

    if useBgRender and self.bgOnRender then
      term.setBackgroundColor(self.bgOnRender)
    else
      self.bgOnRender = term.getBackgroundColor()
    end

    local color = self.colors.background or self.reader:get("Appearance.UserInterface.Button.Background")

    if self.isBeingClicked == true then
      color = self.colors.clicking or self.reader:get("Appearance.UserInterface.Button.Clicking")
    elseif self.isFocused == true then
      color = self.colors.focused or self.reader:get("Appearance.UserInterface.Button.Focused")
    end

    drawing.drawBorder(self.x - 1, self.y - 1, #displayStr + 2, 3, color, "1-box")

    term.setCursorPos(self.x, self.y)
    term.setBackgroundColor(self.colors.background or self.reader:get("Appearance.UserInterface.Button.Background"))
    term.setTextColor(self.disabled and 
      (self.colors.textDisabled or self.reader:get("Appearance.UserInterface.Button.TextDisabled")) 
      or (self.colors.text or self.reader:get("Appearance.UserInterface.Button.Text"))
    )
    
    term.write(displayStr)

    self.renderedWidth = #displayStr

    term.setBackgroundColor(self.bgOnRender)
    term.setCursorPos(oX, oY)

    term.redirect(oT)
  end
end

--- Clicks a button.
-- @tparam[opt] boolean isFirst This is used for clicking with the mouse, mouse_click will make this true.  
function button:click(isFirst)
  expect(1, isFirst, "boolean", "nil")

  if isFirst == true then
    self.isBeingClicked = true
    self:render(true)
  else
    self.isBeingClicked = false
    self.callback()
    self:setFocused(true)
    self:render(true)
  end
end

--- Removes a button
function button:remove()
  self.removed = true
  self.visible = false
end

return button