local w, h = term.getSize()

local fileUtils = require(".lib.utils.file")
local eventManager = require(".lib.events"):new()

local uiManager = require(".lib.ui.uiManager"):new()
local buttons = require(".lib.ui.button")
local mainScrollbox = require(".lib.ui.scrollbox"):new{
  x = 1,
  y = 4,
  w = w + 1,
  h = h - 3,
  parent = term.current(),
  renderScrollbars = { y = true },
  defaultColor = colors.white,
}

local generalFunctions = require(".bin.Settings.generalSettingsFunctions")

local cachedPages = {
  ["index.json"] = fileUtils.readJSON("/bin/Settings/Pages/index.json"),
}

local existingButtons = {}

local currentPage = cachedPages["index.json"]
local backButton = buttons:new{ x = 3, y = 2, text = "\27", callback = function() end, visible = false, }

local function drawNavigationOption(text, description, y, t, renderArrow, i)
  t.setTextColor(colors.black)
  t.setCursorPos(2, y)
  t.write(text)

  if renderArrow then
    term.setCursorPos(w - 2, y)
    term.write("\26")
  end

  t.setTextColor(colors.gray)
  t.setCursorPos(2, y + 1)
  t.write(description)

  t.setTextColor(colors.gray)
  t.setCursorPos(2, y + 2)
  t.write(" ")

  if i and existingButtons[i] then
    existingButtons[i]:reposition(w - #existingButtons[i].text - 3, y)
    existingButtons[i]:render()
  end
end

local function setupPage(data)
  for _, v in pairs(existingButtons) do
    v:remove()
  end

  existingButtons = {}

  if data.type == "control" then
    for i, v in pairs(data.options) do
      if v.action.type == "settingsFunction" then
        local button = buttons:new{ x = 3, y = 3, text = v.action.text, callback = generalFunctions[v.action["function"]], term = mainScrollbox:getTerminal() }
        uiManager:addButton(button, mainScrollbox)
        existingButtons[i] = button
      end
    end
  end
end

local function render(isLoading)
  local oW, oH = w, h
  w, h = term.getSize()

  term.setBackgroundColor(colors.white)
  term.clear()

  if isLoading then
    term.setCursorPos(w / 2 - 4, h / 2)
    term.setTextColor(colors.black)
    term.write("Loading...")
    mainScrollbox:setVisible(false)
    backButton:setVisible(false)
    return
  else
    mainScrollbox:setVisible(true)
  end

  if oW ~= w or oH ~= h then
    mainScrollbox:reposition(1, 4, w, h - 3)
  end

  backButton:render()
  backButton:setVisible(currentPage.title ~= "Home")

  term.setCursorPos(currentPage.title ~= "Home" and 8 or 3, 2)
  term.setTextColor(colors.black)
  term.write(currentPage.title)
  
  local c = term.current()
  local box = mainScrollbox:getTerminal()
  term.redirect(box)

  term.setBackgroundColor(colors.white)
  term.clear()

  if currentPage.type == "control" then
    for i, v in pairs(currentPage.options) do
      drawNavigationOption(v.title, v.description, (i - 1) * 3 + 1, box, v.action.type == "openPage", i)
      term.setBackgroundColor(colors.white)
    end
  end
  
  term.redirect(c)
end

local function navigate(page)
  render(true)

  mainScrollbox:resetScroll()

  if cachedPages[page] == nil then
    if page:gmatch(".json$") then
      cachedPages[page] = fileUtils.readJSON("/bin/Settings/Pages/" .. page)
    end
  end

  currentPage = cachedPages[page]

  setupPage(cachedPages[page])
  render()
end

backButton:setCallback(function() 
  if currentPage.previous then
    navigate(currentPage.previous)
    backButton:setFocused(false)
  end
end)

uiManager:inject(eventManager)
eventManager:addListener("term_resize", render)

eventManager:addListener("mouse_click", function(m, x, y)
  if m == 1 then
    if currentPage.type == "control" then
      local _, sY = mainScrollbox:getScroll()
      local y = y - sY - 2

      for i, v in pairs(currentPage.options) do
        if y >= (i - 1) * 3 + 1 and y <= (i - 1) * 3 + 2 then
          if v.action.type == "openPage" then
            navigate(v.action.page)
          end
        end
      end
    end
  end
end)

mainScrollbox:addToEventManager(eventManager)
uiManager:addButton(backButton)

render()

eventManager:listen()