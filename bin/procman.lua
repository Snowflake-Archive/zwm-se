local eventManager = require(".lib.events"):new()
local buttons = require(".lib.ui.button")
local uiManager = require(".lib.ui.uiManager"):new()
local mainScrollbox = require(".lib.ui.scrollbox"):new(1, 3, 1, 1, term.current(), {y = true})
local utils = require(".lib.utils")
local strings = require("cc.strings")
local w, h = 0, 0
local processes = {}

local selectedTask = nil

local endTask = buttons:new{
  x = 1, 
  y = 1, 
  text = "Kill Task", 
  callback = function()
    _ENV.wm.killProcess(selectedTask)
  end, 
  disabled = true, 
  colors = {
    background = colors.gray,
    clicking = colors.black,
    text = colors.white,
    textDisabled = colors.black,
  },
}

uiManager:addButton(endTask)

local menubar = require(".lib.ui.menubar"):new({
  {
    text = "File",
    objects = {
      {
        text = "Run new task",
        onClick = function()
          _ENV.wm.addProcess("/bin/run.lua", {
            w = 27,
            h = 9,
            title = "Run",
            isCentered = true,
            isResizeable = false,
            hideMaximize = true,
            hideMinimize = true,
          }, true)
        end,
      },
      {
        text = "Exit",
        onClick = function()
          _ENV.wm.killProcess(_ENV.wm.id)
        end,
      },
    },
  },
})

menubar:inject(eventManager, uiManager)
uiManager:inject(eventManager)

local function renderData()
  processes = _ENV.wm.getProcesses()
  processes[0] = {
    title = "System",
    started = _ENV.wm.started,
  }

  local t = mainScrollbox:getTerminal()
  local c = term.current()

  term.redirect(t)
  term.setBackgroundColor(colors.white)
  term.clear()
  term.setTextColor(colors.gray)

  local maxw = 0

  local y = 1
  for i, p in pairs(processes) do
    term.setBackgroundColor(selectedTask == i and colors.lightGray or colors.white)

    local s = strings.ensure_width(p.title:gsub(".lua", ""), w * 0.6)
    term.setCursorPos(1, y)
    term.write((" "):rep(w))
    term.setCursorPos(2, y)
    term.write(s)
    maxw = math.max(maxw, #s)
    y = y + 1
  end

  term.redirect(c)

  local runtimePosition = math.max(w / 2, maxw + 3)

  term.setBackgroundColor(colors.white)
  term.setCursorPos(2, 2)
  term.setTextColor(colors.black)
  term.write("Name")
  term.setCursorPos(runtimePosition, 2)
  term.setTextColor(colors.black)
  term.write("Runtime")

  term.redirect(t)

  y = 1
  for i, p in pairs(processes) do
    term.setBackgroundColor(selectedTask == i and colors.lightGray or colors.white)
    term.setCursorPos(runtimePosition, y)
    term.write(utils.stringifyTime(os.epoch("utc") - p.started))
    y = y + 1
  end

  term.setCursorPos(1, 2)
  term.setBackgroundColor(colors.white)
  term.write(" ")

  term.redirect(c)

  paintutils.drawFilledBox(1, h - 2, w, h, colors.lightGray)
  endTask:reposition(w - 11, h - 1)
  endTask:render()

  menubar:render()
end

local function render()
  w, h = term.getSize()
  term.setBackgroundColor(colors.white)
  term.clear()

  mainScrollbox:reposition(1, 3, w, h - 5)

  renderData()
end

eventManager:addListener("mouse_click", function(m, _, y)
  if m == 1 then
    if y >= 3 and y <= h - 3 then
      local _, sY = mainScrollbox:getScroll()

      local pY = 2 + sY
      selectedTask = nil

      for i in pairs(processes) do
        if y == pY then
          selectedTask = i
          break
        end
        pY = pY + 1
      end

      endTask:setDisabled(selectedTask == nil)
    end
  end
end)

eventManager:addListener("ui_manager_redraw", function(id)
  if id == uiManager:getID() then
    render()
  end
end)

eventManager:addListener("term_resize", function()
  render()
end)

render()

parallel.waitForAll(
  function() 
    eventManager:listen() 
  end, 
  function()
    while true do
      renderData()
      sleep(1)
    end
  end
)