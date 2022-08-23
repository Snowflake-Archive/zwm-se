--- Context menus. This is used across several over components that will be created Soon:tm:
-- @module[kind=ui] ContextMenu

local contextMenu = {}
local strings = require("cc.strings")
local utils = require(".lib.utils")
local ccexpect = require("cc.expect")
local expect, field = ccexpect.expect, ccexpect.field

--- Creates a new context menu via a dictionary.
-- The below parameters are in no particular order.
-- @tparam table objects The objects to add to the context menu.
-- @tparam[opt] table triggerMethod A table used to describe how the context menu will be triggered.
-- @tparam[opt] table colors The colors to use in the context menu.
-- @tparam[opt] boolean dropdownStyle If true, the top of the context menu will be chopped off.
function contextMenu:new(objects)
  local o = {
    objects = field(objects, "objects", "table"),
    colors = field(objects, "colors", "table", "nil"),
    triggerMethod = field(objects, "triggerMethod", "table", "nil"),
    visibleObjects = {},
    dropdownStyle = field(objects, "dropdownStyle", "boolean", "nil") == true, 
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- Renders a context menu.
-- @tparam number x The x position of the context menu.
-- @tparam number y The y position of the context menu.
-- @tparam[opt] boolean objectsOnly If true, only objects will be rendered. This is primarly for internal use.
function contextMenu:render(x, y, objectsOnly, selected)
  if objectsOnly then
    assert(self.visible, "Context menu is not visible.")
    self.visibleObjects = {}

    for i, v in pairs(self.objects) do
      term.setCursorPos(self.renderedX, i + self.renderedY - 1)
      if v.text then
        local oldBackground = term.getBackgroundColor()
        term.setTextColor(v.disabled and colors.gray or colors.black)
        term.setBackgroundColor(i == selected and colors.gray or colors.lightGray)
        term.write(strings.ensure_width(v.text, self.renderedMaxLength))
        term.setBackgroundColor(oldBackground)

        table.insert(self.visibleObjects, {
          i = i,
          o = v,
          y = i + self.renderedY - 1,
        })
      elseif v.seperator then
        term.setTextColor(colors.gray)
        term.write(utils.getPixelChar(false, false, true, true, false, false):rep(self.renderedMaxLength))
      end
    end
  else  
    expect(1, x, "number")
    expect(2, y, "number")

    local maxLength = 0

    for _, v in pairs(self.objects) do
      if v.text then
        maxLength = math.max(maxLength, #v.text)
      elseif v.seperator then
        maxLength = math.max(maxLength, 6)
      end
    end

    self.renderedX = x
    self.renderedY = y
    self.renderedMaxLength = maxLength
    paintutils.drawFilledBox(x - 1, y, x + maxLength + 1, y + #self.objects - 1, colors.lightGray)
    self.visible = true

    self:render(nil, nil, true, selected)
  end

  if selected then self.selected = selected end
end

--- Sets the objects of the context menu.
-- @tparam table objects The objects to add to the context menu.
function contextMenu:setObjects(objects)
  expect(1, objects, "table")
  self.objects = objects
end

--- Sets the objects of the context menu.
-- @tparam table objects The objects to add to the context menu.
function contextMenu:setTriggerMethod(triggerMethod)
  expect(1, triggerMethod, "table")
  self.triggerMethod = triggerMethod
end

--- Hides the context menu.
function contextMenu:hide()
  self.visibleObjects = {}
  self.visible = false
  self.selected = nil
end

--- Removes a context menu
function contextMenu:remove()
  self:hide()
  self.removed = true
end

return contextMenu

