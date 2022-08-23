--- Bars with context menus
-- @module[kind=ui] MenuBar

local menubar = {}

local contextMenuManager = require(".lib.ui.contextMenu")
local expect = require("cc.expect").expect

--- Creates a new menu bar.
-- @tparam options The options to use.
function menubar:new(options)
  local menus = {}

  for i, v in ipairs(options) do
    menus[i] = {
      menu = contextMenuManager:new(v.objects, nil, nil, true),
      text = v.text,
    }
  end

  local o = {
    menus = menus,
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

--- Renders the menubar.
function menubar:render()
  local color = term.getBackgroundColor()
  
  term.setCursorPos(1, 1)
  term.setBackgroundColor(colors.lightGray)
  term.clearLine()

  local cX, cY = 1, 1

  for _, v in pairs(self.menus) do
    term.setCursorPos(cX, cY)
    term.setBackgroundColor(v.menu.visible and colors.gray or colors.lightGray)
    term.setTextColor(colors.black)
    term.write((" %s "):format(v.text))
    cX = cX + #v.text + 2

    if v.menu.visible then
      v.menu:render(v.menu.renderedX, v.menu.renderedY, nil, v.menu.selected)
    end
  end

  term.setBackgroundColor(color)
end

---Adds the MenuBar's events into event managers.
-- @tparam table eventManager The event manager to add the events to.
-- @tparam table uiManager The ui manager to add the events to.
function menubar:inject(eventManager, uiManager)
  expect(1, eventManager, "table")
  expect(2, uiManager, "table")

  eventManager:addListener("mouse_click", function(m, x, y)
    local mX = 1

    local found = false
    for _, v in pairs(self.menus) do
      if v.menu.visible == true then
        found = true
      else
        v.menu:hide()
      end
    end

    if found == false then
      self.shown = nil
      os.queueEvent("ui_manager_redraw", uiManager.id)
      uiManager.hasContextMenuVisible = nil
      self:render()
    end

    if m == 1 and y == 1 then
      for i, v in pairs(self.menus) do
        if x >= mX and x <= mX + #v.text + 2 then
          for _, v in pairs(self.menus) do
            v.menu:hide()
          end
          v.menu:render(mX + 1, 2)
          self.shown = i
          os.queueEvent("ui_manager_redraw", uiManager.id)
          uiManager.hasContextMenuVisible = i
          break
        end
        mX = mX + #v.text + 2
      end
    end
  end)

  for _, v in pairs(self.menus) do
    uiManager:addContextMenu(v.menu)
  end
end

return menubar