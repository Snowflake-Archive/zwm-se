--- Layout with tabs.
-- @module[kind=ui] TabbedLayout

local tabbedLayout = {}
local expect = require("cc.expect").expect

--- Creates a new Tabbed Layout.
-- @tparam table tabs A table of tabs.
-- @tparam[opt] number selectedTab The index of the selected tab.
-- @tparam[opt] number y The Y position of the layout.
-- @return TabbedLayout The new tabbed layout.
function tabbedLayout:new(tabs, selectedTab, y)
  expect(1, tabs, "table")
  expect(2, selectedTab, "number", "nil")
  expect(3, y, "number", "nil")

  local y = y or 1

  local windows = {}
  local native = term.current()
  local w, h = native.getSize()

  for i in pairs(tabs) do
    windows[i] = window.create(native, 1, y, w, h - y, false)

    if selectedTab == i then
      windows[i].setVisible(true)
    end
  end

  local o = {
    tabs = tabs,
    windows = windows,
    selectedTab = selectedTab or 1,
    native = native,
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

--- Sets the selected tab.
-- @tparam number tab The index of the tab to select.
function tabbedLayout:setSelectedTab(tabID)
  self.selectedTab = tabID
  self:render()
end

--- Gets the currently selected tab.
-- @return number The index of the selected tab.
function tabbedLayout:getSelectedTab()
  return self.selectedTab
end

--- Fires the specified function when the tab changes.
-- @tparam function func The function to call when the tab is selected.
function tabbedLayout:onTabChange(f)
  self.onTabChange = f
end

--- Renders the layout.
function tabbedLayout:render()
  term.redirect(self.native)
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.setCursorPos(1, 1)
  term.clearLine()

  local x = 1
  for i, v in pairs(self.tabs) do
    self.windows[i].setVisible(i == self.selectedTab)

    term.setCursorPos(x, 1)

    if i == self.selectedTab then
      term.setBackgroundColor(colors.white)
    else
      term.setBackgroundColor(colors.lightGray)
    end

    term.setTextColor(colors.black)
    term.write((" %s "):format(v))

    x = x + #self.tabs[i] + 2
  end
end

--- Fires events for the layout.
-- @tparam table e The event to fire.
function tabbedLayout:fire(e)
  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    if m ~= 1 then return end

    local s = 1
    for i, v in pairs(self.tabs) do
      local l = #v + 2

      if x >= s and x <= s + l - 1 and y == 1 then
        if i ~= self.selectedTab then
          if self.onTabChange then
            self.onTabChange(i)
            self.selectedTab = i
          end
        end

        self:setSelectedTab(i)
      end

      s = s + l
    end
  end
end

return tabbedLayout