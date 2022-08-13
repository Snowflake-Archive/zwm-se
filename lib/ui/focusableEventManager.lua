--- An event manager to be used with inputs and buttons.
-- @module[kind=ui] FocusableEventManager

local expect = require("cc.expect").expect

local focusableEventManager = {}

--- Creates a new FocusableEventManager.
-- @return FocusableEventManager The event manager.
function focusableEventManager:new()
  local o = {
    objects = {},
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

--- Adds a button to the event manager.
-- @tparam Button button The button to add.
function focusableEventManager:addButton(object)
  expect(1, object, "table")

  table.insert(self.objects, {
    type = "button",
    o = object,
  })
end

--- Adds an input to the event manager.
-- @tparam Input input The input to add.
function focusableEventManager:addInput(object)
  expect(1, object, "table")

  table.insert(self.objects, {
    type = "input",
    o = object,
  })
end

--- Checks events.
-- @tparam table e The event.
function focusableEventManager:check(e)
  expect(1, e, "table")

  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    for _, v in pairs(self.objects) do
      if m == 1 then
        if v.type == "button" and v.o.disabled == false and v.o.visible == true then
          if v.o.visible and v.o.renderedWidth and y == v.o.y and x >= v.o.x and x <= v.o.x + v.o.renderedWidth - 1 then        
            v.o:click(true)
          elseif v.o.isFocused then
            v.o.isFocused = false
            v.o:render(true)
          end
        elseif v.type == "input" and v.o.disabled == false and v.o.visible == true then
          if x >= v.o.x and x <= v.o.x + v.o.w - 1 and v.o.y == y then
            v.o:setFocused(true)
          elseif v.isFocused == true then
            v.o.onComplete(v.o.content, "defocus")
            v.o:setFocused(false) 
          else
            v.o:setFocused(false) 
          end
        end
      end
    end
  elseif e[1] == "mouse_up" then
    local m, x, y = e[2], e[3], e[4]
    for _, v in pairs(self.objects) do
      if m == 1 then
        if v.type == "button" then
          if v.o.visible and v.o.y == y and x >= v.o.x and x <= v.o.x + #v.o.text + 1 and v.o.isBeingClicked == true then
            v.o:setFocused(true)
            v.o:click()
          end
        end
      end
    end

    for _, v in pairs(self.objects) do
      if v.type == "button" then
        v.o.isBeingClicked = false
        v.o:render(true)
      end
    end
  elseif e[1] == "key" or e[1] == "char" then
    for _, v in pairs(self.objects) do
      if v.type == "input" and v.o.isFocused then
        v.o:fire(e)
      end
    end
  end
end

--- Injects the event manager into the event manager.
-- @tparam EventManager manager The event manager to inject into.
function focusableEventManager:inject(manager)
  expect(1, manager, "table")

  manager:addListener("mouse_click", function(...) self:check({"mouse_click", ...}) end)
  manager:addListener("mouse_up", function(...) self:check({"mouse_up", ...}) end)
  manager:addListener("key", function(...) self:check({"key", ...}) end)
  manager:addListener("char", function(...) self:check({"char", ...}) end)
end

return focusableEventManager