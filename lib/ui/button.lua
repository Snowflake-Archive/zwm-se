--- Buttons
-- @moudle[kind=ui] Button
-- @author Marcus Wenzel

local util = require(".lib.util")

local button = {
  eventManager = {}
}

--- Creates a new button. The buttons width will be #text + 4.
-- @tparam number x The X position of the button
-- @tparam number y The Y position of the button
-- @tparam string text The text that will be rendered inside the button.
-- @tparam function callback The function that is ran when the button is clicked.
-- @tparam boolean disabled If this is true, the button will be grayed out and not be selectable.
-- @tparam boolean visible If this is false, the button will not be rendered, nor selectable.
-- @return Button The new button.
function button:new(x, y, text, callback, disabled, visible)
  local o = {
    x = x,
    y = y,
    text = text,
    callback = callback,
    disabled = disabled == true,
    isFocused = false,
    isBeingClicked = false,
    visible = visible or true,
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

--- Repositions a button.
-- @tparam number x The X position to move the button to.
-- @tparam number y The Y position to move the button to.
function button:reposition(x, y)
  self.x = x 
  self.y = y
end

--- Sets the text of a button.
-- @tparam string text The new text of the button.
function button:setText(text)
  self.text = text
  self:render(true)
end

--- Sets whether or not the button is disabled. If this is true, the button will be greyed out and not selectable.
-- @tparam boolean disabled Whether the button is disabled or not.
function button:setDisabled(disabled)
  self.disabled = disabled == true
  self:render(true)
end

--- Sets whether or not the button is visible.
-- @tparam boolean visible Whether or not the button is disabled.
function button:setVisible(visible)
  self.visible = visible == true
end

--- Renders the button.
-- @tparam boolean useBgRender If this is true, the button will be rendered with the same background color used to render it last time.
function button:render(useBgRender)
  if self.visible == true then
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

--- Focuses a button.
function button:focus()
  self.isFocused = true
  self:render(true)
end

--- Unfocuses a button.
function button:unfocus()
  self.isFocused = false
  self:render(true)
end

--- Clicks a button.
-- @tparam boolean isFirst This is used for clicking with the mouse, mouse_click will make this true.  
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

--- Creates a new ButtonEventManager.
-- @return ButtonEventManager The event manager.
function button.eventManager:new()
  local o = {
    buttons = {}
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

--- Adds a button to the ButtonEventManager.
-- @tparam Button button The button to add.
function button.eventManager:add(button)
  table.insert(self.buttons, button)
end

--- Injects listeners into an EventManager.
-- @tparam EventManager manager The event manager to add to.
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