local util = require(".lib.utils")
local input = require(".lib.ui.input")
local button = require(".lib.ui.button")
local eventManager = require(".lib.events")
local scrollbox = require(".lib.ui.scrollbox")
local focusableEventManager = require(".lib.ui.focusableEventManager")
local RegistryReader = require(".lib.registry.Reader")
local RegistryWriter = require(".lib.registry.Writer")
local strings = require("cc.strings")

local menu = {}

local searchLaunch = {}
local searchContent = ""

local searchIgnore = {
  "bin/Assets",
  "bin/Prompts",
  "bin/Registry",
  "bin/ReigstryDefaults",
  "bin/Services",
  "bin/WindowManagerModules",
  "bin/processStopped.lua",
  "bin/startup.lua",
  "bin/wm.lua",
  "lib",
  "rom/apis",
  "rom/modules",
  "rom/programs/advanced",
  "rom/programs/command",
  "rom/programs/fun/advanced/paint.lua",
  "rom/programs/fun/speaker.lua",
  "rom/programs/http",
  "rom/programs/pocket/equip.lua",
  "rom/programs/pocket/unequip.lua",
  "rom/programs/rednet",
  "rom/programs/turtle",
  "rom/programs/about.lua",
  "rom/programs/alias.lua",
  "rom/programs/apis.lua",
  "rom/programs/attach.lua",
  "rom/programs/cd.lua",
  "rom/programs/clear.lua",
  "rom/programs/config.lua",
  "rom/programs/copy.lua",
  "rom/programs/delete.lua",
  "rom/programs/detach.lua",
  "rom/programs/drive.lua",
  "rom/programs/edit.lua",
  "rom/programs/eject.lua",
  "rom/programs/env.lua",
  "rom/programs/exit.lua",
  "rom/programs/gps.lua",
  "rom/programs/help.lua",
  "rom/programs/id.lua",
  "rom/programs/label.lua",
  "rom/programs/list.lua",
  "rom/programs/mkdir.lua",
  "rom/programs/monitor.lua",
  "rom/programs/motd.lua",
  "rom/programs/mount.lua",
  "rom/programs/move.lua",
  "rom/programs/peripherals.lua",
  "rom/programs/programs.lua",
  "rom/programs/reboot.lua",
  "rom/programs/redstone.lua",
  "rom/programs/rename.lua",
  "rom/programs/screenfetch.lua",
  "rom/programs/set.lua",
  "rom/programs/shutdown.lua",
  "rom/programs/time.lua",
  "rom/programs/type.lua",
  "rom/programs/unmount.lua", 
  "rom/autorun",
  "rom/motd.txt",
  "rom/startup.lua",
}

--- Creates a window renderr manager.
-- @return WindowRenderer The window renderer
function menu:new(logger, buffer, wm)
  local o = {
    fullRender = false,
    wm = wm,
    logger = logger,
    processPositions = {},
    isMenuVisible = false,
    term = term.current(),
    searchLaunch = {},
    buffer = buffer,
  }

  setmetatable(o, self)
  self.__index = self

  return o
end

function menu:init()
  self.eventManager = eventManager:new()
  self.focusableEventManager = focusableEventManager:new()

  self.registry = RegistryReader:new("user")
  self.regWrite = RegistryWriter:new("user")

  self.scroll = scrollbox:new(1, 1, 15, 10, self.buffer, {y = true}, false)

  self.searchInput = input:new(1, 1, 9, function(data)
    searchContent = data
    self:renderScrollbox()
  end, function() end, "Search...", nil, nil, false)

  self.shutdownButton = button:new{
    x = 1, 
    y = 1, 
    text = "O", 
    callback = function()
      self.wm.addProcess("/bin/shutdown.lua", {
        hideFrame = true, 
        w = 24, 
        h = 9, 
        isCentered = true,
        title = "Power",
      }, true)
      self:setMenuVisible(false)
    end,
    visible = false, 
    disablePadding = true,
    colors = {
      background = self.registry:get("Appearance.Menu.ShutdownBackground"),
      clicking = self.registry:get("Appearance.Menu.ShutdownFocused"),
      text = self.registry:get("Appearance.Menu.ShutdownText"),
    },
  }

  self.scroll:addToEventManager(self.eventManager)
  self.focusableEventManager:addInput(self.searchInput)
  self.focusableEventManager:addButton(self.shutdownButton)
  self.focusableEventManager:inject(self.eventManager)
end

function menu:renderScrollbox()
  local t = self.scroll:getTerminal()

  if #searchContent > 0 then
    t.setBackgroundColor(colors.gray)
    t.setTextColor(colors.white)
    t.clear()
    
    local programs = {}

    local function search(dir, deep)
      local items = fs.list(dir)

      if deep > 5 then
        return
      end

      for _, item in pairs(items) do
        if not util.tableContains(searchIgnore, fs.combine(dir, item)) then
          if fs.isDir(fs.combine(dir, item)) then
            search(fs.combine(dir, item), deep + 1)
          elseif item:find(searchContent) and item:match("%.lua$") then
            programs[#programs + 1] = {
              dir = dir,
              path = fs.combine(dir, item),
            }
          end
        end
      end
    end

    local function beginSearch()
      search("/", 0)
    end

    local ok = pcall(beginSearch)

    if not ok then
      local str = "An error occured while searching. If you are using Lua patterns, make sure the pattern is complete."
      local split = strings.wrap(str, 14)

      for i, v in pairs(split) do
        t.setCursorPos(1, i)
        t.write(v)
      end
    else
      t.setCursorPos(1, 1)
      t.write(("%d results"):format(#programs))

      searchLaunch = {}

      for i, v in pairs(programs) do
        t.setCursorPos(1, i * 3)
        t.setTextColor(colors.white)
        t.write(strings.ensure_width(fs.getName(v.path), 14))
        t.setCursorPos(1, i * 3 + 1)
        t.setTextColor(colors.lightGray)
        t.write(strings.ensure_width(v.dir, 12))

        local isFavorited = false

        for _, v2 in pairs(self.registry:get("Menu.PinnedApps")) do
          if fs.combine(v2.path) == v.path then
            isFavorited = true
            break
          end
        end

        t.setTextColor(isFavorited == true and colors.red or colors.lightGray)
        t.write(" \3")
        searchLaunch[#searchLaunch + 1] = {
          y = i * 3,
          path = v.path,
        }
      end
    end
  else
    t.setBackgroundColor(colors.gray)
    t.setTextColor(colors.white)
    t.clear()
    t.setCursorPos(1, 1)
    t.write("Pinned Apps")
    t.setCursorPos(1, 10)

    for i, v in pairs(self.registry:get("Menu.PinnedApps")) do
      t.setCursorPos(1, 1 + i)
      t.setTextColor(colors.white)
      t.write("\7 ")
      t.setTextColor(colors.lightBlue)
      t.write(v.name)
    end
  end

  t.setTextColor(colors.lightGray)
end

function menu:setMenuVisible(value)
  self.isMenuVisible = value
end

function menu:render(processes)
  if processes then
    self.processes = processes
  end

  -- Prep
  local oldX, oldY = term.getCursorPos()
  local oldColor = term.getTextColor()
  term.redirect(self.buffer)
  local w, h = term.getSize()
  self.w = w
  self.h = h

  -- Render menubar
  term.setCursorPos(1, h)
  term.setTextColor(self.registry:get("Appearance.Menu.MenuText"))
  term.setBackgroundColor(self.registry:get("Appearance.Menu.MenuBackground"))
  term.clearLine()
  
  term.setTextColor(self.isMenuVisible and self.registry:get("Appearance.Menu.MenuFocusedText") or self.registry:get("Appearance.Menu.MenuText"))
  term.setBackgroundColor(self.isMenuVisible and self.registry:get("Appearance.Menu.MenuFocusedBackground") or self.registry:get("Appearance.Menu.MenuBackground"))
  
  term.write(" + ")

  --[[
  TODO: make this work properly

  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.gray)
  local time = os.time("ingame")
  local timeString = textutils.formatTime(time, true)
  term.setCursorPos(w - #timeString, h)
  term.write(timeString)
  ]]

  -- Render processes on menubar
  term.setCursorPos(4, h)
  self.processPositions = {}

  if self.processes then
    for i, v in pairs(self.processes) do
      if v.isService ~= true then
        local x = term.getCursorPos()
        term.setTextColor(v.focused and self.registry:get("Appearance.Menu.MenuFocusedText") or self.registry:get("Appearance.Menu.MenuText"))
        term.setBackgroundColor(v.focused and self.registry:get("Appearance.Menu.MenuFocusedBackground") or self.registry:get("Appearance.Menu.MenuBackground"))

        term.write((" %s "):format(v.title or fs.getName(v.startedFrom)))
        local xE = term.getCursorPos()

        table.insert(self.processPositions, {
          min = x,
          max = xE - 1,
          id = i,
        })
      end
    end
  end

  if self.isMenuVisible then
    paintutils.drawFilledBox(1, h - 14, 16, h - 1, self.registry:get("Appearance.Menu.MenuBackground"))
    term.setTextColor(self.registry:get("Appearance.Menu.MenuText"))

    -- Make everything visible
    self.shutdownButton:setVisible(true)
    self.searchInput:setVisible(true)
    self.scroll:setVisible(true)
  
    -- Move items to desired positions
    self.searchInput:reposition(2, h - 2)
    self.shutdownButton:reposition(15, h - 2)
    self.scroll:reposition(2, h - 13)
    self.scroll:redraw()

    self.searchInput:render()

    self.shouldCursorBlink = term.getCursorBlink()
    self.cursorBlinkX, self.cursorBlinkY = term.getCursorPos()
  else
    self.shutdownButton:setVisible(false)
    self.searchInput:setVisible(false)
  end

  

  term.setTextColor(oldColor)
  term.setCursorPos(oldX, oldY)
end

function menu:fire(e)
  self.eventManager:check(e)
  local oldIsMenuVisible = self.isMenuVisible

  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    if self.w and self.h and self.isMenuVisible and x >= 1 and x <= 16 and y >= self.h - 14 and y <= self.h - 1 then
      if x >= 2 and x <= 14 and y >= self.h - 13 and y <= self.h - 5 then
        local _, sY = self.scroll:getScroll()

        if searchContent ~= "" then
          for _, v in pairs(searchLaunch) do
            if x >= 2 and x <= 14 and y >= self.h - 15 + sY + v.y and y <= self.h - 14 + sY + v.y then
              if y == self.h - 14 + sY + v.y and x == 14 then
                local isFavorited
                local pinned = self.registry:get("Menu.PinnedApps")
                
                for i, v2 in pairs(pinned) do
                  if fs.combine(v2.path) == fs.combine(v.path) then
                    isFavorited = i
                    break
                  end
                end

                if isFavorited then
                  pinned[isFavorited] = nil
                  self.regWrite:set("Menu.PinnedApps", pinned)
                else
                  table.insert(pinned, {
                    path = v.path,
                    name = fs.getName(v.path)
                  })
                end
        
                self:renderScrollbox()
                break
              else
                self.wm.addProcess(v.path, {title = v.name}, true)
                self.isMenuVisible = false
                break
              end
            end
          end
        else
          for i, v in pairs(self.registry:get("Menu.PinnedApps")) do
            if x >= 4 and x <= 3 + #v.name and y == self.h - 13 + sY + i - 1 then
              self.wm.addProcess(v.path, {title = v.name}, true)
              self.isMenuVisible = false
            end
          end
        end
      end
    elseif m == 1 then
      if y == self.h then
        for _, v in pairs(self.processPositions) do
          if x >= v.min and x <= v.max then
            self.wm.setFocus(v.id, true)
          end
        end

        if x >= 1 and x <= 3 then
          self.searchInput:setFocused(true)
          searchContent = ""
          self.searchInput:setContent("")
          self.isMenuVisible = not self.isMenuVisible
        else
          self.searchInput:setFocused(false)
          self.isMenuVisible = false
        end
      else
        self.searchInput:setFocused(false)
        self.isMenuVisible = false
      end
    else
      self.searchInput:setFocused(false)
      self.isMenuVisible = false
    end
  end

  if oldIsMenuVisible ~= self.isMenuVisible then
    self.scroll:setVisible(self.isMenuVisible)

    if self.isMenuVisible then
      self:renderScrollbox()
    end

    self:render()
  end

  local oFullRender = self.fullRender
  self.fullRender = false

  return oldIsMenuVisible ~= self.isMenuVisible or oFullRender == true
end

return menu