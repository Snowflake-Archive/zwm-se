--- An event manager to be used with UI components.
-- @module[kind=ui] UI Manager

local expect = require("cc.expect").expect

local uiManager = {}

-- Button Events
local function fireButtonEvents(o, e)
  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]

    if m == 1 then
      for _, v in pairs(o) do
        if v.disabled == false and v.visible == true then
          if v.visible and v.renderedWidth and y == v.y and x >= v.x and x <= v.x + v.renderedWidth - 1 then        
            v:click(true)
          elseif v.isFocused then
            v.isFocused = false
            v:render(true)
          end
        end
      end
    end
  elseif e[1] == "mouse_up" then
    local m, x, y = e[2], e[3], e[4]

    if m == 1 then
      for _, v in pairs(o) do
        if v.visible and v.y == y and x >= v.x and x <= v.x + #v.text + 1 and v.isBeingClicked == true then
          v:setFocused(true)
          v:click()
        end
      end
    end

    for _, v in pairs(o) do
      v.isBeingClicked = false
      v:render(true)
    end
  end
end

-- Input Events
local function fireInputEvents(o, e)
  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]

    if m == 1 then
      for _, v in pairs(o) do
        if v.disabled == false and v.visible == true then
          if x >= v.x and x <= v.x + v.w - 1 and v.y == y then
            v:setFocused(true)
          elseif v.isFocused == true then
            v.onComplete(v.content, "defocus")
            v:setFocused(false) 
          else
            v:setFocused(false) 
          end
        end
      end
    end
  elseif e[1] == "key" or e[1] == "char" then
    for _, v in pairs(o) do
      if v.isFocused then
        v:fire(e)
      end
    end
  end
end

-- Context Menu Events
local function fireContextMenuEvents(o, e, hasContextMenuVisible)
  if e[1] == "mouse_click" or e[1] == "mouse_drag" or e[1] == "mouse_up" then
    local m, x, y = e[2], e[3], e[4]

    if hasContextMenuVisible == nil and e[1] == "mouse_click" then
      for i, v in pairs(o) do
        if v.triggerMethod.type == "rightClick" and m == 2 then
          v:render(x + 1, y + 1)
          v.isVisible = true
          return i
        end
      end
    elseif hasContextMenuVisible ~= nil then
      local menu = o[hasContextMenuVisible]

      if x >= menu.renderedX - 1 and y >= menu.renderedY - 1 and x <= menu.renderedX + menu.renderedMaxLength + 1 and y <= menu.renderedY + #menu.visibleObjects + 1 then
        if e[1] == "mouse_click" or e[1] == "mouse_drag" then
          local foundY = false
          for _, v in pairs(menu.visibleObjects) do
            if v.y == y and (v.o.disabled == nil or v.o.disabled == false) then
              menu:render(nil, nil, true, v.i)
              foundY = true
            end
          end

          if foundY == false then
            menu:render(nil, nil, true)
          end
        elseif e[1] == "mouse_up" then
          for _, v in pairs(menu.visibleObjects) do
            if v.y == y then
              if v.o.onClick then
                v.o:onClick()
              end
              
              menu:hide()
              os.queueEvent("ui_manager_redraw")
              return nil
            end
          end
        end
      else
        menu:hide()
        os.queueEvent("ui_manager_redraw")
        return nil
      end
    end
  end

  return hasContextMenuVisible
end

--- Creates a new UIManager.
-- @return UIManager The event manager.
function uiManager:new()
  local o = {
    buttons = {},
    inputs = {},
    contextMenus = {},
    id = math.random(1, 10 ^ 10),
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

--- Adds a button to the event manager.
-- @tparam Button button The button to add.
function uiManager:addButton(object)
  expect(1, object, "table")

  table.insert(self.buttons, object)
end

--- Adds an input to the event manager.
-- @tparam Input input The input to add.
function uiManager:addInput(object)
  expect(1, object, "table")

  table.insert(self.inputs, object)
end

--- Adds a context menu to the event manager.
-- @tparam ContextMenu contextMenu The context menu to add.
function uiManager:addContextMenu(object)
  expect(1, object, "table")

  table.insert(self.contextMenus, object)
end

--- Checks events.
-- @tparam table e The event.
function uiManager:check(e)
  expect(1, e, "table")

  fireButtonEvents(self.buttons, e)
  fireInputEvents(self.inputs, e)
  self.hasContextMenuVisible = fireContextMenuEvents(self.contextMenus, e, self.hasContextMenuVisible)
end

--- Injects the event manager into the event manager.
-- @tparam EventManager manager The event manager to inject into.
function uiManager:inject(manager)
  expect(1, manager, "table")

  manager:addListener("mouse_click", function(...) self:check({"mouse_click", ...}) end)
  manager:addListener("mouse_drag", function(...) self:check({"mouse_drag", ...}) end)
  manager:addListener("mouse_up", function(...) self:check({"mouse_up", ...}) end)
  manager:addListener("key", function(...) self:check({"key", ...}) end)
  manager:addListener("char", function(...) self:check({"char", ...}) end)
end

return uiManager